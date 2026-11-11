# =============================================================================
#  helpers/config.R  -  every tunable model constant lives here (no magic
#  numbers hidden in the code).  Change a value, re-run the app, done.
# =============================================================================
CFG <- list(
  # --- road network model (used when real OSRM geometry is NOT downloaded) ---
  circuity      = c(plain = 1.20, floodplain = 1.25, coastal = 1.25, hill = 1.45),
  terrain_speed = c(plain = 1.00, floodplain = 0.90, coastal = 0.90, hill = 0.60),
  speed_nh      = 55,     # km/h, loaded truck on a National Highway
  speed_sh      = 40,     # km/h, loaded truck on a State Highway
  truck_time_factor = 1.30,  # OSRM car travel time -> loaded relief truck

  # --- Weighted Risk Index cost model ---
  rain_slowdown   = 0.45,  # at hazard exposure 1 trucks run at 55% speed
  wri_cost_factor = 2,     # cost = time * (1 + lambda * WRI/100 * factor)

  # --- demand model ---
  demand_hazard_uplift = 1.5,  # demand x (1 + uplift * local hazard)

  # --- hazard feeds ---
  rain_min_mm   = 30,      # forecast rain below this is not a hazard
  rain_ref_mm   = 115.6,   # IMD "very heavy rain" = severity 1
  flood_min_ratio = 1.8,   # river discharge / recent median to count as a flood signal
  flood_full_ratio = 4.5,  # ratio at which flood severity = 1
  flood_min_flow = 5,      # m3/s - ignore cells with (almost) no river
  cache_minutes = 30       # cache for static (historical) API calls
)

# Historical events that can be replayed with real ERA5 rainfall (Open-Meteo archive)
HIST_EVENTS <- list(
  none = list(label = "(choose an event)", start = NULL, end = NULL, hubs = NULL, camps = NULL),
  kerala2018 = list(label = "Kerala floods, Aug 2018",
                    start = "2018-08-14", end = "2018-08-18",
                    hubs = c("BLR", "CHE", "MUM"), camps = c("KOC", "TVM", "CBE", "MNG")),
  chennai2015 = list(label = "Chennai floods, Nov-Dec 2015",
                     start = "2015-11-30", end = "2015-12-02",
                     hubs = c("BLR", "VJA", "HYD"), camps = c("CHE", "MDU")),
  uttarakhand2013 = list(label = "Uttarakhand cloudburst, Jun 2013",
                         start = "2013-06-15", end = "2013-06-18",
                         hubs = c("DEL", "CHD"), camps = c("DDN", "CHD")),
  fani2019 = list(label = "Cyclone Fani (Odisha), May 2019",
                  start = "2019-05-02", end = "2019-05-04",
                  hubs = c("KOL", "RPR", "VJA"), camps = c("PUR", "BBS", "CTC")),
  assam2024 = list(label = "Assam floods, Jul 2024",
                   start = "2024-07-02", end = "2024-07-06",
                   hubs = c("GHY", "KOL", "PAT"), camps = c("DIB", "SHL", "SIL", "SLG"))
)

hist_choices <- function() {
  stats::setNames(names(HIST_EVENTS), vapply(HIST_EVENTS, function(h) h$label, character(1)))
}
