# =============================================================================
#  helpers/osrm.R  -  build REAL road geometry, distance and travel time for
#  every highway corridor from OpenStreetMap through the public OSRM server.
#  Run once (button in the app, or data-raw/build_real_roads.R); the result is
#  cached in data/osrm_edges.rds and picked up automatically by load_network().
#  Needs internet and takes about 1-2 minutes (one polite request per road).
# =============================================================================
osrm_leg <- function(lon1, lat1, lon2, lat2) {
  co <- cbind(c(lon1, lon2), c(lat1, lat2))
  r <- osrm_snap(co)
  if (is.null(r)) {                       # one polite retry
    Sys.sleep(1.5)
    r <- osrm_snap(co)
  }
  r
}

build_osrm_edges <- function(edges, file = "data/osrm_edges.rds", pause = 0.4,
                             progress = NULL) {
  n <- nrow(edges)
  km <- rep(NA_real_, n); hours <- rep(NA_real_, n); geom <- vector("list", n)
  for (i in seq_len(n)) {
    if (!is.null(progress)) progress(i, n, paste(edges$from[i], "-", edges$to[i]))
    r <- osrm_leg(edges$lon1[i], edges$lat1[i], edges$lon2[i], edges$lat2[i])
    if (!is.null(r)) {
      km[i] <- r$km; hours[i] <- r$hours; geom[[i]] <- r$line
    }
    Sys.sleep(pause)
  }
  n_ok <- sum(is.finite(km))
  if (n_ok < 0.5 * n) return(list(ok = FALSE, n_ok = n_ok, n = n))
  saveRDS(list(key = paste(edges$from, edges$to), km = km, hours = hours,
               geom = geom, built = Sys.time()), file)
  list(ok = TRUE, n_ok = n_ok, n = n)
}
