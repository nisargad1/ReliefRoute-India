# =============================================================================
#  helpers/vrp.R  -  multi-stop convoy planning (capacitated vehicle routing)
#  Clarke-Wright savings heuristic: one truck can serve several camps on the
#  same tour instead of one truck per camp.
# =============================================================================

#' d0: cost depot -> customer (vector length n); cc: n x n customer cost matrix;
#' demand: tonnes per customer (each <= capacity); capacity: tonnes per truck.
#' Returns a list of tours: list(stops = <customer indices in order>, load = t).
clarke_wright <- function(d0, cc, demand, capacity) {
  n <- length(demand)
  if (n == 0) return(list())
  routes <- as.list(seq_len(n))
  loads <- as.numeric(demand)
  rid <- seq_len(n)                       # route id of every customer
  if (n > 1) {
    pr <- which(upper.tri(cc), arr.ind = TRUE)
    sav <- d0[pr[, 1]] + d0[pr[, 2]] - cc[pr]
    ok <- is.finite(sav) & sav > 0
    pr <- pr[ok, , drop = FALSE]
    sav <- sav[ok]
    for (k in order(sav, decreasing = TRUE)) {
      i <- pr[k, 1]; j <- pr[k, 2]
      ri <- rid[i]; rj <- rid[j]
      if (ri == rj) next
      if (loads[ri] + loads[rj] > capacity) next
      a <- routes[[ri]]; b <- routes[[rj]]
      if (a[length(a)] == i) {
        a2 <- a
      } else if (a[1] == i) {
        a2 <- rev(a)
      } else next
      if (b[1] == j) {
        b2 <- b
      } else if (b[length(b)] == j) {
        b2 <- rev(b)
      } else next
      routes[[ri]] <- c(a2, b2)
      loads[ri] <- loads[ri] + loads[rj]
      routes[rj] <- list(NULL)
      loads[rj] <- 0
      rid[routes[[ri]]] <- ri
    }
  }
  keep <- which(!vapply(routes, is.null, logical(1)))
  lapply(keep, function(k) list(stops = routes[[k]], load = loads[k]))
}

#' Convoy plan for ONE hub.
#'   q   : named numeric, tonnes to deliver per camp id (> 0)
#'   cap : truck capacity (t)
#'   Dr  : risk-weighted cost matrix, Dk : km matrix (both with dimnames = node ids,
#'         containing the hub and all camps)
#' Full truck-loads go straight to the camp; the remainders are combined into
#' multi-stop tours with Clarke-Wright.
plan_convoys <- function(hub, q, cap, Dr, Dk) {
  rows <- list()
  camps <- names(q)
  full <- floor(q / cap + 1e-9)
  rem <- q - full * cap
  for (cid in camps[full > 0]) {
    km <- 2 * Dk[hub, cid]
    rows[[length(rows) + 1]] <- data.frame(
      Hub = hub, Stops = cid, Load = cap, Trucks = full[[cid]],
      Km = km, DirectKm = km, stringsAsFactors = FALSE)
  }
  rc <- camps[rem > 1e-9]
  if (length(rc) > 0) {
    tours <- clarke_wright(Dr[hub, rc], Dr[rc, rc, drop = FALSE], rem[rc], cap)
    for (tr in tours) {
      st <- rc[tr$stops]
      km <- Dk[hub, st[1]] + Dk[st[length(st)], hub]
      if (length(st) > 1) {
        for (m in seq_len(length(st) - 1)) km <- km + Dk[st[m], st[m + 1]]
      }
      rows[[length(rows) + 1]] <- data.frame(
        Hub = hub, Stops = paste(st, collapse = ">"), Load = tr$load, Trucks = 1,
        Km = km, DirectKm = sum(2 * Dk[hub, st]), stringsAsFactors = FALSE)
    }
  }
  if (length(rows) == 0) return(NULL)
  do.call(rbind, rows)
}
