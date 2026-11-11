# =============================================================================
#  helpers/geo.R  -  geometry helpers (base R + sf)
# =============================================================================

#' Great-circle distance in km (haversine formula), fully vectorised.
haversine_km <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180
  dlat <- (lat2 - lat1) * rad
  dlon <- (lon2 - lon1) * rad
  a <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
  2 * 6371.0088 * asin(pmin(1, sqrt(a)))
}

#' Distance (km) from point P to the segment A-B (equirectangular projection
#' around P, accurate enough for hazard radii of 10-200 km). Vectorised.
pt_seg_km <- function(px, py, ax, ay, bx, by) {
  kx <- 111.32 * cos(py * pi / 180)
  ky <- 110.57
  x1 <- (ax - px) * kx; y1 <- (ay - py) * ky
  x2 <- (bx - px) * kx; y2 <- (by - py) * ky
  vx <- x2 - x1; vy <- y2 - y1
  den <- vx^2 + vy^2
  t <- ifelse(den == 0, 0, -(x1 * vx + y1 * vy) / den)
  t <- pmax(0, pmin(1, t))
  sqrt((x1 + t * vx)^2 + (y1 + t * vy)^2)
}

#' Circle (as an sf POLYGON) around a lon/lat point with radius in km.
circle_polygon <- function(lon, lat, r_km, n = 40) {
  ang <- seq(0, 2 * pi, length.out = n + 1)
  dlat <- r_km / 110.57
  dlon <- r_km / (111.32 * cos(lat * pi / 180))
  m <- cbind(lon + dlon * cos(ang), lat + dlat * sin(ang))
  m[n + 1, ] <- m[1, ]                      # make sure the ring is closed
  sf::st_polygon(list(m))
}

#' Make a (possibly self-intersecting, hand drawn) polygon valid for GEOS.
safe_valid <- function(geom) {
  tryCatch({
    v <- sf::st_make_valid(sf::st_sfc(geom, crs = 4326))
    v[[1]]
  }, error = function(e) geom)
}

#' Convert a GeoJSON feature coming from leaflet.draw (via Shiny) to sf POLYGON.
feature_to_polygon <- function(f) {
  tryCatch({
    if (is.null(f$geometry) || !identical(f$geometry$type, "Polygon")) return(NULL)
    xy <- as.numeric(unlist(f$geometry$coordinates))
    if (length(xy) < 6 || length(xy) %% 2 != 0) return(NULL)
    m <- matrix(xy, ncol = 2, byrow = TRUE)
    if (!all(m[1, ] == m[nrow(m), ])) m <- rbind(m, m[1, ])
    if (nrow(m) < 4) return(NULL)
    safe_valid(sf::st_polygon(list(m)))
  }, error = function(e) NULL)
}

#' Pretty "2 d 5 h" / "7.5 h" formatting for hours.
fmt_hours <- function(h) {
  vapply(h, function(x) {
    if (is.na(x) || !is.finite(x)) return("-")
    if (x < 1) return(sprintf("%d min", round(x * 60)))
    if (x < 24) return(sprintf("%.1f h", x))
    hh <- round(x)
    sprintf("%d d %d h", hh %/% 24, hh %% 24)
  }, character(1))
}

#' Indian-style thousands separators for rupees (12,34,567).
fmt_inr <- function(x) {
  vapply(x, function(v) {
    if (is.na(v) || !is.finite(v)) return("-")
    v <- round(v)
    s <- format(abs(v), scientific = FALSE, trim = TRUE)
    n <- nchar(s)
    if (n > 3) {
      last3 <- substr(s, n - 2, n)
      rest <- substr(s, 1, n - 3)
      groups <- character(0)
      while (nchar(rest) > 2) {
        groups <- c(substr(rest, nchar(rest) - 1, nchar(rest)), groups)
        rest <- substr(rest, 1, nchar(rest) - 2)
      }
      if (nchar(rest) > 0) groups <- c(rest, groups)
      s <- paste0(paste(groups, collapse = ","), ",", last3)
    }
    paste0(ifelse(v < 0, "-", ""), "₹", s)
  }, character(1))
}
