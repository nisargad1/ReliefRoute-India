# =============================================================================
#  helpers/hazards.R  -  hazard layer: demo scenarios + LIVE public APIs
#
#  Every hazard is a row in one tidy data.frame:
#     source | label | lat | lon | radius_km | severity (0-1) | kind
#  so scenario hazards, live hazards and user-drawn risk circles can all be
#  combined with rbind() and fed to the same Weighted-Risk-Index engine.
#
#  Live sources (all FREE, no API key):
#     * Open-Meteo forecast API  -> 3-day rainfall forecast for every city
#     * USGS Earthquake feed     -> recent M4+ earthquakes in/near India
#     * NASA EONET v3            -> open natural events (floods, storms, ...)
# =============================================================================

HZ_COLS <- c("source", "label", "lat", "lon", "radius_km", "severity", "kind")

empty_hz <- function() {
  data.frame(source = character(), label = character(), lat = numeric(),
             lon = numeric(), radius_km = numeric(), severity = numeric(),
             kind = character(), stringsAsFactors = FALSE)
}

make_hz <- function(source, label, lat, lon, radius_km, severity, kind) {
  data.frame(source = source, label = label, lat = lat, lon = lon,
             radius_km = radius_km, severity = pmin(1, pmax(0, severity)),
             kind = kind, stringsAsFactors = FALSE)
}

rbind_hz <- function(...) {
  parts <- Filter(function(x) !is.null(x) && nrow(x) > 0, list(...))
  if (length(parts) == 0) return(empty_hz())
  out <- do.call(rbind, lapply(parts, function(x) x[, HZ_COLS, drop = FALSE]))
  rownames(out) <- NULL
  out
}

# ---------------------------------------------------------------------------
#  Demo scenarios (clearly SIMULATED - used for classroom demonstration and as
#  an offline fallback when the live APIs are unreachable)
# ---------------------------------------------------------------------------
SCENARIOS <- list(
  none = list(
    label = "No simulated hazard (live data only)",
    hubs = c("DEL", "LKO", "KOL", "PAT"), camps = c("MZF", "DBG", "GHY"),
    hz = NULL),
  bihar_assam = list(
    label = "Monsoon floods - Bihar & Assam (simulated)",
    hubs = c("DEL", "LKO", "KOL", "PAT"),
    camps = c("MZF", "DBG", "SLG", "GHY", "DIB", "GKP"),
    hz = list(
      c("Kosi/Bagmati basin flood", 26.15, 86.10, 110, 0.90),
      c("Brahmaputra flood, Upper Assam", 27.00, 93.40, 120, 0.80),
      c("Teesta flood, North Bengal", 26.75, 88.60, 70, 0.75),
      c("Ghaghra overflow", 26.55, 83.60, 60, 0.60))),
  odisha_cyclone = list(
    label = "Severe cyclone - Odisha / Andhra coast (simulated)",
    hubs = c("KOL", "RPR", "VJA", "HYD"),
    camps = c("PUR", "BBS", "CTC", "BAM", "VSK"),
    hz = list(
      c("Cyclone landfall zone", 19.80, 85.90, 130, 1.00),
      c("Storm surge belt, Ganjam", 19.30, 84.90, 90, 0.80),
      c("Heavy rain band, Visakhapatnam", 17.70, 83.20, 80, 0.60))),
  himalaya = list(
    label = "Cloudburst / landslides - J&K & Uttarakhand (simulated)",
    hubs = c("CHD", "DEL", "AMR"),
    camps = c("SRN", "JMU", "DDN"),
    hz = list(
      c("Landslide cluster, Banihal corridor", 33.45, 75.20, 55, 0.85),
      c("Cloudburst, Garhwal", 30.45, 78.20, 50, 0.75),
      c("Flash flood, Jhelum valley", 34.05, 74.80, 40, 0.70))),
  kerala_coast = list(
    label = "Coastal floods - Kerala & Karnataka (simulated)",
    hubs = c("BLR", "CHE", "MUM"),
    camps = c("KOC", "TVM", "MNG", "CBE"),
    hz = list(
      c("Periyar / Ernakulam flooding", 10.05, 76.35, 80, 0.85),
      c("Coastal Karnataka deluge", 13.00, 74.85, 70, 0.75),
      c("Western Ghats landslides", 11.30, 76.30, 55, 0.70)))
)

scenario_choices <- function() {
  stats::setNames(names(SCENARIOS), vapply(SCENARIOS, function(s) s$label, character(1)))
}

scenario_hazards <- function(key) {
  sc <- SCENARIOS[[key]]
  if (is.null(sc) || is.null(sc$hz)) return(empty_hz())
  rows <- lapply(sc$hz, function(v) {
    make_hz("Simulated scenario", v[1], as.numeric(v[2]), as.numeric(v[3]),
            as.numeric(v[4]), as.numeric(v[5]), "scenario")
  })
  do.call(rbind, rows)
}

# ---------------------------------------------------------------------------
#  Live API helpers
# ---------------------------------------------------------------------------
.hz_cache <- new.env()

#' Tiny time-to-live cache (used for static historical API calls).
cached <- function(key, ttl_min, fn) {
  hit <- .hz_cache[[key]]
  if (!is.null(hit) && difftime(Sys.time(), hit$t, units = "mins") < ttl_min) return(hit$v)
  v <- fn()
  if (!is.null(v)) assign(key, list(t = Sys.time(), v = v), envir = .hz_cache)
  v
}

http_get_json <- function(url, timeout_s = 10) {
  resp <- httr::GET(url, httr::timeout(timeout_s),
                    httr::user_agent("ReliefRouteIndia/2.0 (student R project)"))
  if (httr::status_code(resp) != 200) stop("HTTP ", httr::status_code(resp))
  txt <- httr::content(resp, as = "text", encoding = "UTF-8")
  jsonlite::fromJSON(txt, simplifyVector = FALSE)
}

#' Open-Meteo multi-location replies: one object per location (a list), or a
#' single object when only one location was requested.
as_location_list <- function(js, n) {
  if (!is.null(js$daily)) js <- list(js)
  if (length(js) != n) stop("unexpected reply size")
  js
}

#' JSON arrays can contain null: turn a list into a numeric vector with NA.
num_vec <- function(x) {
  vapply(x, function(z) if (is.null(z)) NA_real_ else suppressWarnings(as.numeric(z)), numeric(1))
}

#' Max daily rainfall (mm) per node from an Open-Meteo reply.
rain_from_json <- function(js, nodes) {
  js <- as_location_list(js, nrow(nodes))
  mm <- vapply(js, function(x) {
    v <- num_vec(x$daily$precipitation_sum)
    v <- v[!is.na(v)]
    if (length(v) == 0) 0 else max(v)
  }, numeric(1))
  data.frame(id = nodes$id, name = nodes$name, lat = nodes$lat, lon = nodes$lon,
             mm = mm, stringsAsFactors = FALSE)
}

#' Convert a rain table into hazard rows (heavy rain -> circle around the city).
rain_to_hz <- function(rain, source, kind) {
  wet <- rain[rain$mm >= CFG$rain_min_mm, , drop = FALSE]
  if (nrow(wet) == 0) return(empty_hz())
  make_hz(source, sprintf("%s: %.0f mm/day", wet$name, wet$mm),
          wet$lat, wet$lon, pmin(120, 50 + wet$mm / 2), wet$mm / CFG$rain_ref_mm, kind)
}

coord_query <- function(nodes) {
  paste0("latitude=", paste(round(nodes$lat, 3), collapse = ","),
         "&longitude=", paste(round(nodes$lon, 3), collapse = ","))
}

#' 3-day rainfall forecast (max daily mm) for every node via Open-Meteo.
fetch_rain <- function(nodes) {
  out <- list(rain = NULL, hz = empty_hz(), msg = "")
  tryCatch({
    url <- paste0("https://api.open-meteo.com/v1/forecast?", coord_query(nodes),
                  "&daily=precipitation_sum&forecast_days=3&timezone=Asia%2FKolkata")
    rain <- rain_from_json(http_get_json(url, 15), nodes)
    out$rain <- rain
    out$hz <- rain_to_hz(rain, "Open-Meteo rain forecast", "live")
    out$msg <- sprintf("Open-Meteo rain forecast OK (%d cities, %d wet zones)", nrow(rain), nrow(out$hz))
  }, error = function(e) {
    out$msg <<- paste("Open-Meteo rain forecast unavailable:", conditionMessage(e))
  })
  out
}

#' HISTORICAL replay: real ERA5 reanalysis rainfall for a past date range.
fetch_archive_rain <- function(nodes, start, end) {
  out <- list(rain = NULL, hz = empty_hz(), msg = "")
  tryCatch({
    key <- paste("arch", start, end)
    rain <- cached(key, CFG$cache_minutes, function() {
      url <- paste0("https://archive-api.open-meteo.com/v1/archive?", coord_query(nodes),
                    "&start_date=", start, "&end_date=", end,
                    "&daily=precipitation_sum&timezone=Asia%2FKolkata")
      rain_from_json(http_get_json(url, 25), nodes)
    })
    out$rain <- rain
    out$hz <- rain_to_hz(rain, "ERA5 historical rain (Open-Meteo)", "history")
    out$msg <- sprintf("ERA5 replay %s to %s OK (%d wet zones, peak %.0f mm/day)",
                       start, end, nrow(out$hz), max(rain$mm, na.rm = TRUE))
  }, error = function(e) {
    out$msg <<- paste("ERA5 historical rain unavailable:", conditionMessage(e))
  })
  out
}

#' River-flood signal: GloFAS river discharge forecast (Open-Meteo Flood API).
#' flood ratio = max forecast discharge (next 7 days) / median of last 30 days.
fetch_flood <- function(nodes) {
  out <- list(hz = empty_hz(), msg = "")
  tryCatch({
    url <- paste0("https://flood-api.open-meteo.com/v1/flood?", coord_query(nodes),
                  "&daily=river_discharge&past_days=30&forecast_days=7")
    js <- as_location_list(http_get_json(url, 25), nrow(nodes))
    rows <- list()
    for (i in seq_along(js)) {
      v <- num_vec(js[[i]]$daily$river_discharge)
      if (length(v) < 20) next
      nf <- 7
      hist <- v[seq_len(length(v) - nf)]; fc <- v[(length(v) - nf + 1):length(v)]
      hist <- hist[!is.na(hist)]; fc <- fc[!is.na(fc)]
      if (length(hist) < 10 || length(fc) == 0) next
      base <- stats::median(hist)
      if (!is.finite(base) || base < CFG$flood_min_flow) next
      ratio <- max(fc) / base
      if (ratio < CFG$flood_min_ratio) next
      sev <- (ratio - CFG$flood_min_ratio) / (CFG$flood_full_ratio - CFG$flood_min_ratio)
      rows[[length(rows) + 1]] <- make_hz(
        "GloFAS river flood (Open-Meteo)",
        sprintf("%s: river discharge %.1fx recent median", nodes$name[i], ratio),
        nodes$lat[i], nodes$lon[i], 55, 0.25 + 0.75 * min(1, sev), "live")
    }
    if (length(rows) > 0) out$hz <- do.call(rbind, rows)
    out$msg <- sprintf("GloFAS flood forecast OK (%d flood signals)", nrow(out$hz))
  }, error = function(e) {
    out$msg <<- paste("GloFAS flood forecast unavailable:", conditionMessage(e))
  })
  out
}

#' Recent earthquakes (last 14 days, M >= 4.0) in the Indian region via USGS.
fetch_quakes <- function() {
  out <- list(hz = empty_hz(), msg = "")
  tryCatch({
    start <- format(Sys.Date() - 14, "%Y-%m-%d")
    url <- paste0(
      "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson",
      "&minmagnitude=4&minlatitude=5&maxlatitude=37.5",
      "&minlongitude=67&maxlongitude=98&orderby=time&limit=60&starttime=", start)
    js <- http_get_json(url, 12)
    feats <- js$features
    if (length(feats) == 0) {
      out$msg <- "USGS earthquakes OK (no M4+ quakes in India region, last 14 days)"
      return(out)
    }
    rows <- lapply(feats, function(f) {
      mag <- suppressWarnings(as.numeric(f$properties$mag))
      co <- as.numeric(unlist(f$geometry$coordinates))
      if (length(mag) != 1 || is.na(mag) || length(co) < 2) return(NULL)
      place <- if (is.null(f$properties$place)) "India region" else f$properties$place
      make_hz("USGS earthquake", sprintf("M%.1f - %s", mag, place),
              co[2], co[1], 15 + 25 * (mag - 4), (mag - 3.5) / 3, "live")
    })
    rows <- Filter(Negate(is.null), rows)
    if (length(rows) > 0) out$hz <- do.call(rbind, rows)
    out$msg <- sprintf("USGS earthquakes OK (%d quakes)", nrow(out$hz))
  }, error = function(e) {
    out$msg <<- paste("USGS earthquakes unavailable:", conditionMessage(e))
  })
  out
}

#' Open natural events (floods, storms, landslides, wildfires) via NASA EONET.
fetch_eonet <- function() {
  out <- list(hz = empty_hz(), msg = "")
  tryCatch({
    url <- paste0(
      "https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=100",
      "&category=floods,severeStorms,landslides,wildfires",
      "&bbox=67,37.5,98,5")
    js <- http_get_json(url, 15)
    evs <- js$events
    if (length(evs) == 0) {
      out$msg <- "NASA EONET OK (no open events around India)"
      return(out)
    }
    sev_tab <- c(Floods = 0.70, `Severe Storms` = 0.80, Landslides = 0.75, Wildfires = 0.50)
    rad_tab <- c(Floods = 60, `Severe Storms` = 100, Landslides = 30, Wildfires = 25)
    rows <- list()
    for (e in evs) {
      if (length(e$geometry) == 0) next
      cat_name <- if (length(e$categories) > 0) e$categories[[1]]$title else "Event"
      g <- e$geometry[[length(e$geometry)]]          # most recent geometry
      co <- as.numeric(unlist(g$coordinates))[1:2]   # point, or first polygon vertex
      if (length(co) < 2 || any(is.na(co))) next
      s <- if (cat_name %in% names(sev_tab)) sev_tab[[cat_name]] else 0.5
      r <- if (cat_name %in% names(rad_tab)) rad_tab[[cat_name]] else 40
      rows[[length(rows) + 1]] <- make_hz("NASA EONET", paste0(cat_name, ": ", e$title),
                                          co[2], co[1], r, s, "live")
    }
    if (length(rows) > 0) out$hz <- do.call(rbind, rows)
    out$msg <- sprintf("NASA EONET OK (%d events)", nrow(out$hz))
  }, error = function(e) {
    out$msg <<- paste("NASA EONET unavailable:", conditionMessage(e))
  })
  out
}

#' Fetch all live feeds and combine them (each feed fails independently).
fetch_live_hazards <- function(nodes) {
  r <- fetch_rain(nodes)
  f <- fetch_flood(nodes)
  q <- fetch_quakes()
  e <- fetch_eonet()
  list(hz = rbind_hz(r$hz, f$hz, q$hz, e$hz),
       rain = r$rain,
       msgs = c(r$msg, f$msg, q$msg, e$msg),
       time = format(Sys.time(), "%d %b %Y, %I:%M %p", tz = "Asia/Kolkata"))
}
