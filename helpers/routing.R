# =============================================================================
#  helpers/routing.R  -  the analytical core
#     1. load the India corridor network (nodes + roads) as sf + igraph objects
#     2. hazard exposure along every road segment
#     3. the WEIGHTED RISK INDEX (WRI) and the risk-penalised edge cost
#     4. shortest paths (igraph / Dijkstra) and a min-cost transportation
#        problem (lpSolve) that splits relief stock between hubs and camps
# =============================================================================

# ---------------------------------------------------------------------------
# 1. Network loading
# ---------------------------------------------------------------------------
load_network <- function(dir = "data", use_osrm = TRUE) {
  f_nodes <- file.path(dir, "india_nodes.csv")
  f_roads <- file.path(dir, "india_roads.csv")
  if (!file.exists(f_nodes) || !file.exists(f_roads)) {
    stop("Data files not found. Open the project folder in RStudio ",
         "(File > Open Project / Set Working Directory) and run again.")
  }
  nodes <- utils::read.csv(f_nodes, stringsAsFactors = FALSE)
  edges <- utils::read.csv(f_roads, stringsAsFactors = FALSE)
  stopifnot(all(c(edges$from, edges$to) %in% nodes$id))

  i1 <- match(edges$from, nodes$id)
  i2 <- match(edges$to, nodes$id)
  edges$lon1 <- nodes$lon[i1]; edges$lat1 <- nodes$lat[i1]
  edges$lon2 <- nodes$lon[i2]; edges$lat2 <- nodes$lat[i2]

  # road length = straight line x circuity factor (hill roads wind more)
  edges$km <- haversine_km(edges$lon1, edges$lat1, edges$lon2, edges$lat2) *
    unname(CFG$circuity[edges$terrain])
  # average LOADED-TRUCK speed (km/h): NH / SH, slower on hills and floodplains
  edges$speed <- ifelse(edges$road == "NH", CFG$speed_nh, CFG$speed_sh) *
    unname(CFG$terrain_speed[edges$terrain])
  edges$time0 <- edges$km / edges$speed
  edges$eid   <- seq_len(nrow(edges))
  edges$name  <- paste(nodes$name[i1], "-", nodes$name[i2])
  stopifnot(!anyNA(edges$km), !anyNA(edges$speed))

  lines_list <- lapply(seq_len(nrow(edges)), function(i) {
    sf::st_linestring(matrix(c(edges$lon1[i], edges$lon2[i],
                               edges$lat1[i], edges$lat2[i]), ncol = 2))
  })

  # ---- optional: REAL road geometry / distance / time from OSRM (OpenStreetMap)
  #      (created once with the "Download real roads" button or data-raw script)
  real_roads <- FALSE
  f_osrm <- file.path(dir, "osrm_edges.rds")
  if (isTRUE(use_osrm) && file.exists(f_osrm)) {
    upd <- tryCatch({
      ob <- readRDS(f_osrm)
      idx <- match(paste(edges$from, edges$to), ob$key)
      have <- which(!is.na(idx))
      have <- have[is.finite(ob$km[idx[have]]) & ob$km[idx[have]] > 0]
      if (length(have) < 0.5 * nrow(edges)) NULL else {
        km <- edges$km; time0 <- edges$time0; ll <- lines_list
        for (i in have) {
          j <- idx[i]
          km[i] <- ob$km[j]
          time0[i] <- ob$hours[j] * CFG$truck_time_factor
          m <- ob$geom[[j]]
          if (is.matrix(m) && nrow(m) >= 2 && ncol(m) == 2) ll[[i]] <- sf::st_linestring(m)
        }
        list(km = km, time0 = time0, lines = ll)
      }
    }, error = function(e) NULL)
    if (!is.null(upd)) {
      edges$km <- upd$km
      edges$time0 <- upd$time0
      edges$speed <- edges$km / edges$time0
      lines_list <- upd$lines
      real_roads <- TRUE
    }
  }
  lines <- sf::st_sfc(lines_list, crs = 4326)

  g <- igraph::graph_from_data_frame(
    d = data.frame(from = edges$from, to = edges$to, eid = edges$eid,
                   stringsAsFactors = FALSE),
    directed = FALSE,
    vertices = data.frame(name = nodes$id, stringsAsFactors = FALSE))

  list(nodes = nodes, edges = edges, lines = lines, graph = g, real_roads = real_roads)
}

# ---------------------------------------------------------------------------
# 2. Hazard exposure (0-1) of segments / points
#    exposure = severity * (1 - 0.6 * distance/radius)  inside the radius
# ---------------------------------------------------------------------------
hazard_exposure <- function(hz, ax, ay, bx, by) {
  n <- length(ax)
  if (is.null(hz) || nrow(hz) == 0) return(rep(0, n))
  m <- vapply(seq_len(nrow(hz)), function(i) {
    d <- pt_seg_km(hz$lon[i], hz$lat[i], ax, ay, bx, by)
    ifelse(d <= hz$radius_km[i], hz$severity[i] * (1 - 0.6 * d / hz$radius_km[i]), 0)
  }, numeric(n))
  if (is.null(dim(m))) m <- matrix(m, nrow = n)
  pmin(1, apply(m, 1, max))
}

# ---------------------------------------------------------------------------
# 3. WEIGHTED RISK INDEX (WRI, 0-100) and risk-penalised cost
#
#    WRI_e  = 100 * ( wH*H_e + wR*V_e + wS*S_e ) / (wH + wR + wS)
#       H_e : live + simulated hazard exposure of the segment      (0-1)
#       V_e : structural road vulnerability (floodplain/hill/coast) (0-1)
#       S_e : security / access-constraint index (user editable)    (0-1)
#
#    time_e = base_time / (1 - 0.45 * H_e)          (weather slows trucks)
#    cost_e = time_e * (1 + lambda * WRI_e/100 * 2) (risk-aversion lambda)
#
#    lambda = 0   -> behaves like an ordinary "fastest route" GPS
#    lambda = 10  -> will accept a very long detour to stay safe
# ---------------------------------------------------------------------------
edge_state <- function(edges, lines, hz, nogo_sfc, wH, wR, wS, lambda,
                       auto_block = TRUE, block_thr = 0.85) {
  H <- hazard_exposure(hz, edges$lon1, edges$lat1, edges$lon2, edges$lat2)

  blocked <- rep(FALSE, nrow(edges))
  if (!is.null(nogo_sfc) && length(nogo_sfc) > 0) {
    hit <- tryCatch(
      suppressMessages(sf::st_intersects(lines, nogo_sfc, sparse = FALSE)),
      error = function(e) NULL)
    if (!is.null(hit)) blocked <- rowSums(hit) > 0
  }
  if (isTRUE(auto_block)) blocked <- blocked | (H >= block_thr)

  wsum <- wH + wR + wS
  if (wsum <= 0) { wH <- 1; wR <- 0; wS <- 0; wsum <- 1 }
  wri <- 100 * (wH * H + wR * edges$vuln + wS * edges$security) / wsum

  time_h <- edges$time0 / (1 - CFG$rain_slowdown * H)
  w_risk <- time_h * (1 + lambda * wri / 100 * CFG$wri_cost_factor)

  list(H = H, blocked = blocked, wri = wri, time_h = time_h, w_risk = w_risk,
       w_fast = edges$time0, w_short = edges$km)
}

# ---------------------------------------------------------------------------
# 4a. Shortest path on the graph (Dijkstra via igraph)
# ---------------------------------------------------------------------------
prep_graph <- function(base_g, weights, blocked) {
  g <- base_g
  igraph::E(g)$w <- weights
  if (any(blocked)) g <- igraph::delete_edges(g, which(blocked))
  g
}

route_on <- function(base_g, weights, blocked, from, to) {
  fail <- list(ok = FALSE, v = character(0), e = integer(0))
  if (identical(from, to)) return(list(ok = TRUE, v = from, e = integer(0)))
  g <- prep_graph(base_g, weights, blocked)
  if (igraph::ecount(g) == 0) return(fail)
  sp <- tryCatch(
    suppressWarnings(igraph::shortest_paths(g, from = from, to = to,
                                            weights = igraph::E(g)$w,
                                            output = "both")),
    error = function(e) NULL)
  if (is.null(sp) || length(sp$vpath[[1]]) == 0) return(fail)
  list(ok = TRUE,
       v = igraph::V(g)$name[as.integer(sp$vpath[[1]])],
       e = igraph::E(g)$eid[as.integer(sp$epath[[1]])])
}

#' Cost matrix (hubs x camps); Inf where unreachable.
cost_matrix <- function(base_g, weights, blocked, from_ids, to_ids) {
  g <- prep_graph(base_g, weights, blocked)
  if (igraph::ecount(g) == 0) {
    m <- matrix(Inf, length(from_ids), length(to_ids),
                dimnames = list(from_ids, to_ids))
    m[outer(from_ids, to_ids, "==")] <- 0
    return(m)
  }
  igraph::distances(g, v = from_ids, to = to_ids,
                    weights = igraph::E(g)$w, mode = "all")
}

#' Coordinates of a route: follows the real road geometry when it is loaded,
#' otherwise the straight corridor between city nodes.
route_xy <- function(vnames, eids, lines, nodes) {
  if (length(eids) == 0 || length(vnames) < 2) return(path_coords(vnames, nodes))
  out <- NULL
  for (k in seq_along(eids)) {
    m <- unclass(lines[[eids[k]]])
    p <- nodes[match(vnames[k], nodes$id), ]
    d1 <- (m[1, 1] - p$lon)^2 + (m[1, 2] - p$lat)^2
    d2 <- (m[nrow(m), 1] - p$lon)^2 + (m[nrow(m), 2] - p$lat)^2
    if (d2 < d1) m <- m[nrow(m):1, , drop = FALSE]
    out <- rbind(out, m[, 1:2, drop = FALSE])
  }
  colnames(out) <- c("lon", "lat")
  out
}

path_coords <- function(vnames, nodes) {
  idx <- match(vnames, nodes$id)
  cbind(lon = nodes$lon[idx], lat = nodes$lat[idx])
}

route_metrics <- function(e, st, edges, rs_per_km) {
  if (length(e) == 0) {
    return(list(km = 0, hours = 0, wri_mean = 0, wri_max = 0,
                exposed = 0, blocked_hit = 0, cost_inr = 0))
  }
  km <- edges$km[e]
  list(km = sum(km),
       hours = sum(st$time_h[e]),
       wri_mean = sum(st$wri[e] * km) / sum(km),
       wri_max = max(st$wri[e]),
       exposed = sum(st$H[e] >= 0.30),
       blocked_hit = sum(st$blocked[e]),
       cost_inr = sum(km) * 2 * rs_per_km)      # round trip
}

# ---------------------------------------------------------------------------
# 4b. Fleet distribution = transportation problem (min total risk-weighted cost)
#     A dummy "unmet demand" supplier with a huge cost absorbs any shortfall
#     (not enough stock, or camp cut off by closures).
# ---------------------------------------------------------------------------
solve_allocation <- function(cost, supply, demand) {
  m <- nrow(cost); n <- ncol(cost); big <- 1e6
  c2 <- cost
  c2[!is.finite(c2)] <- big
  c2 <- rbind(c2, rep(big, n))
  sup <- c(supply, sum(demand))

  res <- tryCatch(
    lpSolve::lp.transport(c2, direction = "min",
                          row.signs = rep("<=", m + 1), row.rhs = sup,
                          col.signs = rep("=", n), col.rhs = demand),
    error = function(e) NULL)

  if (!is.null(res) && res$status == 0) {
    flow <- res$solution[seq_len(m), , drop = FALSE]
  } else {                                   # greedy fallback (never fails)
    flow <- matrix(0, m, n)
    sup_left <- supply; dem_left <- demand
    ord <- order(as.vector(cost))
    for (k in ord) {
      i <- (k - 1) %% m + 1; j <- (k - 1) %/% m + 1
      if (!is.finite(cost[i, j])) next
      q <- min(sup_left[i], dem_left[j])
      if (q > 0) { flow[i, j] <- q; sup_left[i] <- sup_left[i] - q; dem_left[j] <- dem_left[j] - q }
    }
  }
  flow[!is.finite(cost)] <- 0
  dimnames(flow) <- dimnames(cost)
  flow
}

demand_tonnes <- function(nodes, node_H, affected_pct, kg_pp_day, days) {
  pop <- nodes$pop_lakh * 1e5
  ceiling(pop * (affected_pct / 100) * (1 + CFG$demand_hazard_uplift * node_H) *
            kg_pp_day * days / 1000)
}

# ---------------------------------------------------------------------------
# 5. Optional: snap a corridor route to real roads with the public OSRM server
# ---------------------------------------------------------------------------
osrm_snap <- function(coords) {
  tryCatch({
    pts <- paste(sprintf("%.5f,%.5f", coords[, 1], coords[, 2]), collapse = ";")
    url <- paste0("https://router.project-osrm.org/route/v1/driving/", pts,
                  "?overview=full&geometries=geojson")
    js <- http_get_json(url, 12)
    if (!identical(js$code, "Ok")) return(NULL)
    r <- js$routes[[1]]
    xy <- do.call(rbind, lapply(r$geometry$coordinates,
                                function(p) c(as.numeric(p[[1]]), as.numeric(p[[2]]))))
    list(line = xy, km = r$distance / 1000, hours = r$duration / 3600)
  }, error = function(e) NULL)
}
