# =============================================================================
#  ReliefRoute India  v2  -  Dynamic Refugee & Humanitarian Supply Chain Router
#  An R / Shiny decision-support dashboard
#
#  HOW TO RUN (RStudio):   open ReliefRoute-India.Rproj, open this file and
#                          click the green "Run App" button
#                          (or in the Console:  shiny::runApp())
#
#  What it does
#    * LIVE hazard overlay: rain forecast, river-flood signal (GloFAS), earthquakes, NASA events
#    * HISTORICAL replay of real disasters with ERA5 reanalysis rainfall
#    * Draw NO-GO polygons directly on the Leaflet map -> roads are closed
#    * WEIGHTED RISK INDEX (WRI) penalty added to every road segment
#    * Min-cost fleet distribution (linear programming) + multi-stop convoys (VRP)
#    * Real OpenStreetMap road geometry (one-click download), supply/demand heat-maps,
#      route comparison, risk sensitivity, CSV upload, downloadable plan + report
# =============================================================================

# ---- 0. Packages (auto-installed on first run) ------------------------------
pkgs_required <- c("shiny", "shinydashboard", "leaflet", "sf", "igraph",
                   "lpSolve", "DT", "plotly", "httr", "jsonlite", "htmltools")
pkgs_optional <- c("leaflet.extras", "rintrojs")   # draw toolbar + heat-maps / guided tour

to_install <- pkgs_required[!vapply(pkgs_required, requireNamespace,
                                    logical(1), quietly = TRUE)]
if (length(to_install) > 0) {
  message("Installing missing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
}
for (pk in pkgs_optional) {
  if (!requireNamespace(pk, quietly = TRUE)) {
    try(install.packages(pk, repos = "https://cloud.r-project.org"), silent = TRUE)
  }
}
HAS_EXTRAS <- requireNamespace("leaflet.extras", quietly = TRUE)
HAS_INTRO  <- requireNamespace("rintrojs", quietly = TRUE)

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(leaflet)
  library(DT)
  library(plotly)
})
suppressMessages(sf::sf_use_s2(FALSE))        # planar maths: robust for hand-drawn polygons

# ---- 1. Project modules -------------------------------------------------------
if (!file.exists("helpers/routing.R")) {
  stop("Please set the working directory to the project folder ",
       "(RStudio: open ReliefRoute-India.Rproj, or Session > Set Working Directory > ",
       "To Source File Location).")
}
for (f in c("geo", "config", "hazards", "routing", "osrm", "vrp", "report")) {
  source(file.path("helpers", paste0(f, ".R")), encoding = "UTF-8")
}

NET   <- load_network("data")
nodes <- NET$nodes
edges <- NET$edges

node_label   <- paste0(nodes$name, " (", nodes$state, ")")
camp_choices <- stats::setNames(nodes$id, node_label)
hub_idx      <- nodes$role == "hub"
hub_choices  <- stats::setNames(nodes$id[hub_idx], node_label[hub_idx])

DEFAULT_SCENARIO <- "bihar_assam"

pal_wri <- colorNumeric(c("#2a9d8f", "#e9c46a", "#f4a261", "#e76f51", "#9d0208"),
                        domain = c(0, 100))
pal_hz  <- colorNumeric(c("#ffd166", "#f77f00", "#d62828", "#6a040f"),
                        domain = c(0, 1))
LANE_COLS <- c("#e63946", "#2a9d8f", "#f4a261", "#6a4c93", "#118ab2",
               "#ef476f", "#06d6a0", "#8338ec", "#fb5607", "#3a86ff")

add_draw_toolbar <- function(map) {
  if (!HAS_EXTRAS) return(map)
  shp <- leaflet.extras::drawShapeOptions(color = "#d90429", fillColor = "#ef233c",
                                          fillOpacity = 0.35, weight = 3)
  leaflet.extras::addDrawToolbar(
    map, targetGroup = "drawn", position = "topleft",
    polylineOptions = FALSE, circleOptions = FALSE, markerOptions = FALSE,
    circleMarkerOptions = FALSE,
    polygonOptions = leaflet.extras::drawPolygonOptions(shapeOptions = shp),
    rectangleOptions = leaflet.extras::drawRectangleOptions(shapeOptions = shp),
    editOptions = leaflet.extras::editToolbarOptions(edit = TRUE, remove = TRUE))
}

add_heat <- function(map, lng, lat, intensity, colours, group) {
  if (!HAS_EXTRAS || length(lng) == 0) return(map)
  tryCatch(
    leaflet.extras::addHeatmap(map, lng = lng, lat = lat, intensity = intensity,
                               max = 1, radius = 48, blur = 36, minOpacity = 0.35,
                               gradient = colours, group = group),
    error = function(e)
      leaflet.extras::addHeatmap(map, lng = lng, lat = lat, intensity = intensity,
                                 max = 1, radius = 48, blur = 36, group = group))
}

# ---- 2. Look & feel (India tricolour inspired) --------------------------------
app_css <- "
body, .content-wrapper, .right-side { background: linear-gradient(160deg,#fff7ec 0%,#eef6ff 55%,#eafaf1 100%) !important; font-family: 'Segoe UI', Roboto, 'Noto Sans', 'Noto Sans Devanagari', Arial, sans-serif; }
.main-header .logo { background: linear-gradient(90deg,#ff9933,#f4623a) !important; font-weight: 800; font-size: 19px; letter-spacing: .3px; }
.main-header .navbar { background: linear-gradient(90deg,#f4623a,#6a4c93 55%,#138808) !important; }
.main-header { box-shadow: 0 3px 0 0 #ffffff, 0 6px 0 0 #138808; }
.main-sidebar, .left-side { background: linear-gradient(180deg,#2b1b5a,#412a7d 60%,#1f6f5c) !important; }
.sidebar-menu > li > a { transition: background .2s, padding-left .2s; }
.sidebar-menu > li > a:hover { padding-left: 20px; background: rgba(255,255,255,.10) !important; }
.sidebar-menu > li.active > a { border-left: 4px solid #ff9933 !important; background: rgba(255,255,255,.14) !important; }
.sidebar-note { padding: 12px 16px; font-size: 12px; color: #e8e1ff; line-height: 1.5; }
.box { border-radius: 14px; box-shadow: 0 4px 14px rgba(60,40,120,.13); overflow: hidden; border-top: 0; }
.box.box-solid.box-primary > .box-header { background: linear-gradient(90deg,#6a4c93,#3a86ff); }
.box.box-solid.box-success > .box-header { background: linear-gradient(90deg,#138808,#2a9d8f); }
.box.box-solid.box-warning > .box-header { background: linear-gradient(90deg,#ff9933,#f4623a); }
.box.box-solid.box-info > .box-header { background: linear-gradient(90deg,#118ab2,#6a4c93); }
.box.box-solid.box-danger > .box-header { background: linear-gradient(90deg,#d62828,#9d0208); }
.small-box { border-radius: 14px; box-shadow: 0 4px 14px rgba(60,40,120,.20); transition: transform .15s; }
.small-box:hover { transform: translateY(-3px); }
.small-box h3 { font-size: 26px; font-weight: 800; }
.nav-tabs-custom { border-radius: 14px; overflow: hidden; box-shadow: 0 4px 14px rgba(60,40,120,.13); }
.nav-tabs-custom > .nav-tabs > li.active { border-top-color: #ff9933; }
.btn-saffron { background:#ff9933; color:#fff; font-weight:700; border:none; border-radius: 8px; }
.btn-saffron:hover { background:#e8841f; color:#fff; }
.btn-green { background:#138808; color:#fff; font-weight:700; border:none; border-radius: 8px; }
.btn-green:hover { background:#0e6a06; color:#fff; }
.btn-purple { background:#6a4c93; color:#fff; font-weight:700; border:none; border-radius: 8px; }
.btn-purple:hover { background:#563d79; color:#fff; }
.hint { color:#5c5470; font-size:12.5px; margin: 2px 0 8px 0; }
.status-pill { display:inline-block; padding:3px 10px; border-radius:20px; background:#ede7ff; color:#3d2a7a; font-size:12px; margin-top:6px; }
.banner { display:flex; flex-wrap:wrap; gap:8px; align-items:center; background:#ffffffcc; border-radius:14px; padding:10px 14px; margin-bottom:14px; box-shadow: 0 4px 14px rgba(60,40,120,.10); }
.banner .pill { padding:4px 12px; border-radius:20px; font-size:12.5px; font-weight:600; color:#fff; }
.pill-purple { background:#6a4c93; } .pill-red { background:#d62828; } .pill-green { background:#138808; }
.pill-orange { background:#f4623a; } .pill-blue { background:#118ab2; } .pill-grey { background:#6c757d; }
.help-card h4 { color:#6a4c93; font-weight:700; }
.hi { font-size: 15.5px; line-height: 1.75; }
table.pkg td, table.pkg th { padding: 5px 10px; border-bottom: 1px solid #eee; }
.leaflet-container { border-radius: 10px; }
#map { min-height: 520px; }
@media (max-width: 767px) {
  .small-box h3 { font-size: 20px; } .banner .pill { font-size: 11.5px; }
  .content-wrapper { padding: 0 4px; } #map { min-height: 420px; }
}
"

# ---- 3. User interface --------------------------------------------------------
ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "ReliefRoute India", titleWidth = 290),
  dashboardSidebar(
    width = 290,
    sidebarMenu(
      id = "tabs",
      menuItem("Command Map / नियंत्रण मानचित्र",
               tabName = "map", icon = icon("map"), selected = TRUE),
      menuItem("Fleet Plan / वाहन योजना",
               tabName = "fleet", icon = icon("truck")),
      menuItem("Convoy Planner / काफ़िला योजना",
               tabName = "convoy", icon = icon("route")),
      menuItem("Route Compare / रूट तुलना",
               tabName = "compare", icon = icon("road")),
      menuItem("Hazard Feed / खतरा सूचना",
               tabName = "hazards", icon = icon("exclamation-triangle")),
      menuItem("Data & Method / डेटा व विधि",
               tabName = "method", icon = icon("database")),
      menuItem("Help / सहायता",
               tabName = "help", icon = icon("question-circle"))
    ),
    div(class = "sidebar-note",
        HTML("<b>Tip:</b> everything recalculates automatically - draw a red
              no-go polygon on the map and watch the fleet plan change.<br><br>
              <b>सुझाव:</b> नक्शे पर लाल बहुभुज बनाइए - रूट और योजना
              अपने-आप बदल जाएंगे।<br><br>
              Emergency: <b>112</b> | Disaster helpline: <b>1078</b>"))
  ),
  dashboardBody(
    tags$head(tags$style(HTML(app_css))),
    if (HAS_INTRO) rintrojs::introjsUI(),
    tabItems(
      # ------------------------------------------------------------------ MAP
      tabItem(
        tabName = "map",
        fluidRow(column(12, uiOutput("banner"))),
        fluidRow(
          valueBoxOutput("vb_demand", width = 2),
          valueBoxOutput("vb_supply", width = 2),
          valueBoxOutput("vb_served", width = 2),
          valueBoxOutput("vb_blocked", width = 2),
          valueBoxOutput("vb_trips", width = 2),
          valueBoxOutput("vb_wri", width = 2)
        ),
        fluidRow(
          column(
            width = 4,
            tabBox(
              width = 12, id = "steps",
              tabPanel(
                "1 Situation / स्थिति",
                selectInput("scenario", "Disaster scenario / आपदा परिदृश्य",
                            choices = scenario_choices(), selected = DEFAULT_SCENARIO),
                div(class = "hint", "Simulated hazards for demonstration. Add real ones below."),
                checkboxInput("use_live", "Include LIVE hazard feeds / लाइव डेटा", TRUE),
                actionButton("fetch_live", "Fetch live hazards (rain, floods, quakes)",
                             icon = icon("cloud"), class = "btn-saffron", width = "100%"),
                div(class = "status-pill", textOutput("live_status", inline = TRUE)),
                hr(),
                tags$b("Replay a REAL past disaster / वास्तविक आपदा रीप्ले"),
                div(class = "hint", "Uses real ERA5 rainfall from Open-Meteo for the chosen days."),
                selectInput("hist_event", NULL, choices = hist_choices(), selected = "assam2024"),
                dateRangeInput("hist_dates", "Date range (max 14 days)",
                               start = "2024-07-02", end = "2024-07-06",
                               min = "1950-01-01", max = Sys.Date() - 5),
                checkboxInput("use_hist", "Include replayed rainfall in routing", TRUE),
                actionButton("load_hist", "Load historical rainfall", icon = icon("history"),
                             class = "btn-purple", width = "100%"),
                div(class = "status-pill", textOutput("hist_status", inline = TRUE))
              ),
              tabPanel(
                "2 Resources / संसाधन",
                selectizeInput("hubs", "Relief hubs (warehouses) / राहत हब",
                               choices = hub_choices, multiple = TRUE,
                               selected = SCENARIOS[[DEFAULT_SCENARIO]]$hubs,
                               options = list(plugins = list("remove_button"))),
                selectizeInput("camps", "Affected cities / camps / प्रभावित शहर",
                               choices = camp_choices, multiple = TRUE,
                               selected = SCENARIOS[[DEFAULT_SCENARIO]]$camps,
                               options = list(plugins = list("remove_button"))),
                sliderInput("affected_pct", "People affected (% of city population)",
                            min = 0.5, max = 10, value = 2, step = 0.5),
                sliderInput("kg_pp", "Relief kg per person per day (food, water, NFI)",
                            min = 0.3, max = 2, value = 0.6, step = 0.1),
                sliderInput("days", "Days of supply", min = 1, max = 14, value = 3),
                sliderInput("stock_mult", "Hub stock multiplier", min = 0.3, max = 3,
                            value = 1, step = 0.1),
                hr(),
                fileInput("custom_csv", "Upload your own relief points (CSV) / अपना CSV",
                          accept = ".csv"),
                div(class = "hint", "Columns: name, lat, lon, type (hub or camp), tonnes.",
                    downloadLink("dl_template", "Download template")),
                div(class = "status-pill", textOutput("custom_status", inline = TRUE))
              ),
              tabPanel(
                "3 Risk / जोखिम",
                div(class = "hint", "Weighted Risk Index (WRI) = weighted mix of the three factors below."),
                sliderInput("wH", "Weight: hazard exposure", 0, 10, 8, step = 1),
                sliderInput("wR", "Weight: road vulnerability (floodplain / hill / coast)", 0, 10, 4, step = 1),
                sliderInput("wS", "Weight: security / access constraint", 0, 10, 3, step = 1),
                sliderInput("lambda", "Risk aversion lambda (0 = fastest like GPS, 10 = safest)",
                            0, 10, 5, step = 0.5),
                checkboxInput("auto_block", "Auto-close roads with severe hazard", TRUE),
                sliderInput("block_thr", "Severity that closes a road", 0.5, 1, 0.85, step = 0.05),
                hr(),
                sliderInput("trucks", "Trucks available", 5, 300, 60, step = 5),
                sliderInput("truck_cap", "Truck capacity (tonnes)", 3, 25, 10),
                sliderInput("rs_per_km", "Operating cost (Rs per km)", 20, 120, 45, step = 5)
              ),
              tabPanel(
                "4 Danger zones / खतरा क्षेत्र",
                div(class = "hint", HTML(
                  "<b>A.</b> Use the polygon/rectangle tools at the top-left of the map to draw a
                   <b style='color:#d90429'>red no-go zone</b> (roads touching it are closed).<br>
                   <b>B.</b> Or choose a click mode below and click on the map to drop a circle.")),
                radioButtons("click_mode", "Map click mode",
                             choices = c("Off (use drawing tools)" = "off",
                                         "Drop NO-GO circle (road closed)" = "nogo",
                                         "Drop RISK circle (penalty only)" = "risk")),
                sliderInput("zone_r", "Circle radius (km)", 10, 200, 50, step = 5),
                sliderInput("zone_sev", "Risk circle severity (0-1)", 0.1, 1, 0.7, step = 0.1),
                fluidRow(
                  column(6, actionButton("undo_zone", "Undo last circle", icon = icon("undo"), width = "100%")),
                  column(6, actionButton("clear_zones", "Clear ALL zones", icon = icon("trash"),
                                         class = "btn-green", width = "100%"))
                ),
                div(class = "status-pill", textOutput("zone_summary", inline = TRUE)),
                if (!HAS_EXTRAS) div(class = "hint", style = "color:#d62828",
                  "Package 'leaflet.extras' is missing: drawing tools and heat-maps are off. Use circles instead, or run install.packages('leaflet.extras').")
              )
            )
          ),
          column(
            width = 8,
            box(width = 12, status = "primary", solidHeader = TRUE,
                title = "Live Operations Map - hazards, risk-coloured roads, optimised fleet routes",
                leafletOutput("map", height = "calc(100vh - 330px)"),
                if (!NET$real_roads)
                  checkboxInput("snap", "Snap routes to real roads with OSRM (needs internet, experimental)", FALSE))
          )
        )
      ),
      # ---------------------------------------------------------------- FLEET
      tabItem(
        tabName = "fleet",
        fluidRow(
          box(width = 12, status = "success", solidHeader = TRUE,
              title = "Optimised fleet distribution (min risk-weighted cost) / वाहन वितरण योजना",
              DT::dataTableOutput("plan_tbl"),
              br(),
              downloadButton("dl_plan", "Download plan (CSV)", class = "btn-saffron"),
              downloadButton("dl_report", "Download situation report (HTML / print to PDF)",
                             class = "btn-purple"))
        ),
        fluidRow(
          box(width = 6, status = "warning", solidHeader = TRUE,
              title = "Demand coverage per city (tonnes)", plotlyOutput("plot_cov", height = 330)),
          box(width = 6, status = "info", solidHeader = TRUE,
              title = "Hub stock usage (tonnes)", plotlyOutput("plot_hub", height = 330))
        )
      ),
      # --------------------------------------------------------------- CONVOY
      tabItem(
        tabName = "convoy",
        fluidRow(
          valueBoxOutput("vb_cv_trucks", width = 4),
          valueBoxOutput("vb_cv_direct", width = 4),
          valueBoxOutput("vb_cv_saved", width = 4)
        ),
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Multi-stop convoys (capacitated vehicle routing, Clarke-Wright savings)",
              div(class = "hint", "Full truck-loads go straight to a camp. The remaining part-loads are combined so one truck serves several camps on one tour, using the risk-aware road network."),
              DT::dataTableOutput("cv_tbl"))
        ),
        fluidRow(
          box(width = 12, status = "success", solidHeader = TRUE,
              title = "Kilometres driven: one truck per camp vs convoy tours",
              plotlyOutput("cv_plot", height = 320))
        )
      ),
      # -------------------------------------------------------------- COMPARE
      tabItem(
        tabName = "compare",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Why not just use a GPS app?  Compare 3 routing strategies",
              fluidRow(
                column(4, selectInput("cmp_from", "From / कहाँ से", choices = camp_choices, selected = "DEL")),
                column(4, selectInput("cmp_to", "To / कहाँ तक", choices = camp_choices, selected = "GHY"))
              ),
              uiOutput("cmp_story"))
        ),
        fluidRow(
          box(width = 7, status = "success", solidHeader = TRUE, title = "Map comparison",
              leafletOutput("map_cmp", height = 470)),
          box(width = 5, status = "warning", solidHeader = TRUE, title = "Numbers",
              DT::dataTableOutput("cmp_tbl"),
              plotlyOutput("cmp_plot", height = 260))
        ),
        fluidRow(
          box(width = 12, status = "info", solidHeader = TRUE,
              title = "Sensitivity: how does the route change as risk aversion (lambda) goes from 0 to 10?",
              plotlyOutput("sweep_plot", height = 330))
        )
      ),
      # -------------------------------------------------------------- HAZARDS
      tabItem(
        tabName = "hazards",
        fluidRow(
          valueBoxOutput("vb_hz_n", width = 4),
          valueBoxOutput("vb_hz_rain", width = 4),
          valueBoxOutput("vb_hz_zones", width = 4)
        ),
        fluidRow(
          box(width = 7, status = "danger", solidHeader = TRUE, title = "All active hazards used for routing",
              DT::dataTableOutput("hz_tbl")),
          box(width = 5, status = "info", solidHeader = TRUE, title = "Feed status",
              uiOutput("live_msgs"),
              plotlyOutput("rain_plot", height = 330))
        )
      ),
      # --------------------------------------------------------------- METHOD
      tabItem(
        tabName = "method",
        fluidRow(
          box(width = 6, status = "primary", solidHeader = TRUE, title = "Method (what the R code does)",
              HTML("
<ol>
<li><b>Network</b> - 48 Indian cities and 69 highway corridors (<code>data/*.csv</code>) are loaded with
<code>read.csv()</code> into an <code>sf</code> line layer and an <code>igraph</code> graph. Real road geometry, distance and time
from OpenStreetMap (via OSRM) replace the straight corridors after one click below.</li>
<li><b>Hazard overlay</b> - live feeds are pulled with <code>httr</code> + <code>jsonlite</code>
(Open-Meteo rain and GloFAS river discharge, USGS, NASA EONET), real past rainfall (ERA5) can be replayed, and
simulated scenarios and user circles are added.</li>
<li><b>Dynamic exclusion zones</b> - polygons drawn with <code>leaflet.extras</code> become
<code>sf</code> objects and are tested with <code>st_intersects()</code>; touched roads are deleted from the graph.</li>
<li><b>Weighted Risk Index</b><br>
<code>WRI = 100 * (wH*H + wR*V + wS*S) / (wH + wR + wS)</code><br>
H = hazard exposure, V = road vulnerability, S = security/access index.<br>
<code>time = base_time / (1 - 0.45*H)</code><br>
<code>cost = time * (1 + lambda * WRI/100 * 2)</code></li>
<li><b>Routing</b> - Dijkstra via <code>igraph::shortest_paths()</code> on the risk-penalised cost.</li>
<li><b>Fleet distribution</b> - a transportation linear programme (<code>lpSolve::lp.transport()</code>)
sends stock from hubs to camps at minimum risk-weighted cost; unmet demand is reported explicitly.</li>
<li><b>Convoys</b> - Clarke-Wright savings heuristic combines part-loads into multi-stop tours.</li>
<li><b>Demand model</b> - tonnes = population x affected% x (1 + 1.5 x hazard) x kg/person/day x days / 1000.</li>
</ol>")),
          box(width = 6, status = "success", solidHeader = TRUE, title = "R packages used",
              HTML("
<table class='pkg'>
<tr><th>Package</th><th>Used for</th></tr>
<tr><td><code>shiny</code>, <code>shinydashboard</code></td><td>Reactive web app and dashboard layout</td></tr>
<tr><td><code>leaflet</code>, <code>leaflet.extras</code></td><td>Interactive maps, draw toolbar, heat-maps</td></tr>
<tr><td><code>sf</code></td><td>Spatial data, polygon / road intersection</td></tr>
<tr><td><code>igraph</code></td><td>Road graph and shortest-path algorithm</td></tr>
<tr><td><code>lpSolve</code></td><td>Linear programming (fleet allocation)</td></tr>
<tr><td><code>httr</code>, <code>jsonlite</code></td><td>Calling live public APIs, parsing JSON</td></tr>
<tr><td><code>DT</code>, <code>plotly</code>, <code>htmltools</code></td><td>Tables, charts, report</td></tr>
<tr><td><code>rintrojs</code></td><td>Guided tour (optional)</td></tr>
<tr><td><code>testthat</code></td><td>Automated tests + GitHub Actions</td></tr>
</table>
<br><b>R skills demonstrated:</b> reactive programming, vectorised geometry,
functional programming (<code>lapply / vapply / Filter</code>), error handling with
<code>tryCatch</code>, modular code with <code>source()</code>, API consumption, optimisation, unit testing.
"),
              hr(),
              tags$b("Road data: "), textOutput("road_status", inline = TRUE),
              br(), br(),
              actionButton("build_roads", "Download real road geometry (OpenStreetMap / OSRM, ~2 min)",
                           icon = icon("download"), class = "btn-saffron"))
        ),
        fluidRow(
          box(width = 12, status = "warning", solidHeader = TRUE, title = "Public datasets & sources",
              HTML("
<ul>
<li><b>Open-Meteo forecast API</b> - rainfall forecast (free for non-commercial use, CC BY 4.0, no key) - live.</li>
<li><b>Open-Meteo Flood API (GloFAS)</b> - river discharge forecast; flood signal = forecast / recent median - live.</li>
<li><b>Open-Meteo Historical API (ERA5)</b> - real past rainfall for disaster replay.</li>
<li><b>USGS Earthquake Hazards</b> GeoJSON API - public domain - live.</li>
<li><b>NASA EONET v3</b> - open natural events (floods, storms, landslides, wildfires) - live.</li>
<li><b>OpenStreetMap / OSRM</b> - real road geometry, distance and travel time (downloaded once).</li>
<li><b>Census of India 2011</b> - approximate city population, rounded - bundled in <code>data/india_nodes.csv</code>.</li>
<li><b>Illustrative inputs</b> - hub stock, road vulnerability and security indices are
<i>assumptions for demonstration</i>; replace them in the CSVs or upload your own points.</li>
</ul>
<p>Extensions: India-WRIS / CWC gauge data and IMD district warnings can be added as extra rows
in the hazard table (same columns).</p>"))
        ),
        fluidRow(
          box(width = 12, status = "info", solidHeader = TRUE, title = "Model constants (helpers/config.R - edit and re-run)",
              DT::dataTableOutput("tbl_cfg"))
        ),
        fluidRow(
          box(width = 6, title = "Cities / hubs (data/india_nodes.csv)", status = "info", solidHeader = TRUE,
              DT::dataTableOutput("tbl_nodes")),
          box(width = 6, title = "Road corridors (data/india_roads.csv)", status = "info", solidHeader = TRUE,
              DT::dataTableOutput("tbl_edges"))
        )
      ),
      tabItem(
        tabName = "help",
        fluidRow(
          box(width = 6, status = "primary", solidHeader = TRUE, title = "How to use (English)",
              HTML("<div class='help-card'>
<h4>Four steps</h4>
<ol>
<li><b>Situation</b> - pick a scenario (e.g. Bihar &amp; Assam floods) and press <i>Fetch live hazards</i>.</li>
<li><b>Resources</b> - choose relief hubs and the affected cities; set people affected and days of supply.</li>
<li><b>Risk</b> - slide <i>risk aversion</i> to the right to avoid dangerous roads even if the trip is longer.</li>
<li><b>Danger zones</b> - draw a red polygon (top-left tools on the map) to close roads, or click the map to drop a circle.</li>
</ol>
<p>Routes, heat-maps, the fleet plan and all numbers update instantly. Use <b>Fleet Plan</b> to download a CSV.</p>
<h4>Colours</h4>
<ul>
<li>Roads: green = low Weighted Risk Index, red = high, dashed black = closed.</li>
<li>Heat-map: warm colours = high relief demand (cyan-green = hub supply).</li>
<li>Coloured thick lines = optimised truck lanes (one colour per hub).</li>
</ul>
<p><b>Important:</b> this is an educational prototype. Use official NDMA, SDMA and IMD advisories for real decisions.
Emergency number 112, disaster helpline 1078.</p></div>")),
          box(width = 6, status = "success", solidHeader = TRUE, title = "उपयोग कैसे करें (हिन्दी)",
              HTML("<div class='hi help-card'>
<h4>चार आसान कदम</h4>
<ol>
<li><b>स्थिति</b> - कोई आपदा परिदृश्य (जैसे बिहार-असम बाढ़) चुनिए और “Fetch live hazards” बटन दबाइए।</li>
<li><b>संसाधन</b> - राहत हब (गोदाम) और प्रभावित शहर चुनिए; प्रभावित लोगों का प्रतिशत और दिन तय कीजिए।</li>
<li><b>जोखिम</b> - “Risk aversion” स्लाइडर दाएँ ले जाएँ ताकि खतरनाक सड़कों से बचते हुए लंबा रास्ता भी चुना जाए।</li>
<li><b>खतरा क्षेत्र</b> - नक्शे के बाएँ ऊपर के औज़ार से लाल बहुभुज बनाइए (प्रवेश-निषेध क्षेत्र), या नक्शे पर क्लिक करके वृत्त जोड़िए।</li>
</ol>
<p>रूट, हीट-मैप और वाहन योजना अपने-आप तुरंत बदल जाते हैं। “Fleet Plan” टैब से CSV डाउनलोड कीजिए।</p>
<h4>रंगों का अर्थ</h4>
<ul>
<li>सड़कें: हरा = कम जोखिम, लाल = अधिक जोखिम, काली टूटी रेखा = सड़क बंद।</li>
<li>हीट-मैप: गर्म रंग = अधिक राहत माँग।</li>
</ul>
<p><b>ज़रूरी:</b> यह एक शैक्षणिक प्रोटोटाइप है। वास्तविक निर्णयों के लिए NDMA, SDMA और IMD की आधिकारिक सूचना का पालन करें।
आपातकालीन नंबर 112, आपदा हेल्पलाइन 1078।</p></div>"))
        ),
        fluidRow(
          box(width = 12, status = "info", solidHeader = TRUE, title = "New tools / नए औज़ार",
              HTML("<ul>
<li><b>Replay a real disaster:</b> Situation tab &rarr; choose an event (Kerala 2018, Assam 2024 ...) &rarr; <i>Load historical rainfall</i>.</li>
<li><b>Real roads:</b> Data &amp; Method tab &rarr; <i>Download real road geometry</i> once, then restart the app.</li>
<li><b>Your own data:</b> Resources tab &rarr; upload a CSV (name, lat, lon, type = hub or camp, tonnes). Download the template there.</li>
<li><b>Convoy Planner:</b> multi-stop truck tours that save kilometres.</li>
<li><b>Report:</b> Fleet Plan tab &rarr; <i>Download situation report</i>, open it and press Ctrl+P to save as PDF.</li>
<li><b>अपना डेटा:</b> संसाधन टैब में CSV अपलोड कीजिए; <b>असली सड़कें:</b> &ldquo;Data &amp; Method&rdquo; टैब से एक बार डाउनलोड कीजिए।</li>
</ul>"))
        )
      )
    )
  )
)

# ---- 4. Server ----------------------------------------------------------------
server <- function(input, output, session) {

  rv <- reactiveValues(zones = list(), seq = 0L, live = NULL, hist = NULL, skip_sc = FALSE)
  snap_cache <- new.env()

  # ---- scenario -> pre-select hubs / camps ----------------------------------
  observeEvent(input$scenario, {
    if (isTRUE(rv$skip_sc)) {            # change came from a historical replay
      rv$skip_sc <- FALSE
      return()
    }
    sc <- SCENARIOS[[input$scenario]]
    updateSelectizeInput(session, "hubs", selected = sc$hubs)
    updateSelectizeInput(session, "camps", selected = sc$camps)
  }, ignoreInit = TRUE)

  # ---- live hazard feeds --------------------------------------------------------
  observeEvent(input$fetch_live, {
    res <- NULL
    withProgress(message = "Contacting Open-Meteo, GloFAS, USGS and NASA EONET ...", value = 0.3, {
      res <- tryCatch(fetch_live_hazards(nodes), error = function(e) NULL)
      setProgress(1)
    })
    if (is.null(res)) {
      showNotification("Live feeds could not be reached. The simulated scenario is still active.",
                       type = "warning", duration = 8)
      return()
    }
    rv$live <- res
    showNotification(sprintf("Live data loaded: %d active hazard zones.", nrow(res$hz)),
                     type = "message", duration = 6)
  })

  output$live_status <- renderText({
    if (is.null(rv$live)) {
      "No live data yet - press the orange button"
    } else {
      paste0("Updated ", rv$live$time, " IST | ", nrow(rv$live$hz), " live zones")
    }
  })

  # ---- historical replay (ERA5) -------------------------------------------------
  observeEvent(input$hist_event, {
    h <- HIST_EVENTS[[input$hist_event]]
    if (!is.null(h) && !is.null(h$start)) {
      updateDateRangeInput(session, "hist_dates", start = h$start, end = h$end)
    }
  }, ignoreInit = TRUE)

  observeEvent(input$load_hist, {
    d <- input$hist_dates
    if (length(d) < 2 || any(is.na(d))) {
      showNotification("Please choose a start and an end date.", type = "warning")
      return()
    }
    if (as.numeric(d[2] - d[1]) > 14 || as.numeric(d[2] - d[1]) < 0) {
      showNotification("Choose a range of 1 to 14 days (end after start).", type = "warning")
      return()
    }
    res <- NULL
    withProgress(message = "Downloading ERA5 rainfall for the chosen days ...", value = 0.3, {
      res <- tryCatch(fetch_archive_rain(nodes, format(d[1], "%Y-%m-%d"), format(d[2], "%Y-%m-%d")),
                      error = function(e) NULL)
      setProgress(1)
    })
    if (is.null(res) || is.null(res$rain)) {
      showNotification(if (is.null(res)) "Historical data could not be reached." else res$msg,
                       type = "warning", duration = 8)
      return()
    }
    rv$hist <- list(hz = res$hz, rain = res$rain, msg = res$msg,
                    label = paste(format(d[1], "%d %b %Y"), "to", format(d[2], "%d %b %Y")))
    h <- HIST_EVENTS[[input$hist_event]]
    if (!is.null(h) && !is.null(h$hubs)) {
      updateSelectizeInput(session, "hubs", selected = h$hubs)
      updateSelectizeInput(session, "camps", selected = h$camps)
      if (!identical(input$scenario, "none")) {
        rv$skip_sc <- TRUE
        updateSelectInput(session, "scenario", selected = "none")
      }
    }
    updateCheckboxInput(session, "use_hist", value = TRUE)
    showNotification(res$msg, type = "message", duration = 8)
  })

  output$hist_status <- renderText({
    if (is.null(rv$hist)) "No historical rainfall loaded" else paste("Replaying", rv$hist$label,
                                                                    "|", nrow(rv$hist$hz), "wet zones")
  })

  # ---- user zones: drawn polygons -----------------------------------------------
  observeEvent(input$map_draw_new_feature, {
    f <- input$map_draw_new_feature
    g <- feature_to_polygon(f)
    if (is.null(g)) return()
    lid <- f$properties$`_leaflet_id`
    rv$seq <- rv$seq + 1L
    id <- if (is.null(lid)) paste0("draw_s", rv$seq) else paste0("draw_", lid)
    rv$zones[[id]] <- list(id = id, kind = "nogo", source = "draw", geom = g,
                           label = "Hand-drawn no-go zone")
  })

  observeEvent(input$map_draw_edited_features, {
    fs <- input$map_draw_edited_features$features
    for (f in fs) {
      lid <- f$properties$`_leaflet_id`
      if (is.null(lid)) next
      id <- paste0("draw_", lid)
      g <- feature_to_polygon(f)
      if (!is.null(g) && !is.null(rv$zones[[id]])) rv$zones[[id]]$geom <- g
    }
  })

  observeEvent(input$map_draw_deleted_features, {
    fs <- input$map_draw_deleted_features$features
    for (f in fs) {
      lid <- f$properties$`_leaflet_id`
      if (!is.null(lid)) rv$zones[[paste0("draw_", lid)]] <- NULL
    }
  })

  # ---- user zones: click-to-drop circles ----------------------------------------
  observeEvent(input$map_click, {
    mode <- input$click_mode
    if (is.null(mode) || mode == "off") return()
    cl <- input$map_click
    rv$seq <- rv$seq + 1L
    id <- paste0("circle_", rv$seq)
    is_nogo <- identical(mode, "nogo")
    rv$zones[[id]] <- list(
      id = id, kind = if (is_nogo) "nogo" else "risk", source = "click",
      geom = circle_polygon(cl$lng, cl$lat, input$zone_r),
      lat = cl$lat, lon = cl$lng, r_km = input$zone_r,
      sev = if (is_nogo) 1 else input$zone_sev,
      label = if (is_nogo) sprintf("No-go circle (%d km)", input$zone_r)
              else sprintf("Risk circle (%d km, severity %.1f)", input$zone_r, input$zone_sev))
  })

  observeEvent(input$undo_zone, {
    z <- rv$zones
    if (length(z) == 0) return()
    ids <- names(z)[vapply(z, function(x) identical(x$source, "click"), logical(1))]
    if (length(ids) > 0) rv$zones[[utils::tail(ids, 1)]] <- NULL
  })

  observeEvent(input$clear_zones, {
    rv$zones <- list()
    if (HAS_EXTRAS) {
      leafletProxy("map") %>%
        leaflet.extras::removeDrawToolbar(clearFeatures = TRUE) %>%
        add_draw_toolbar()
    }
  })

  output$zone_summary <- renderText({
    z <- rv$zones
    n_no <- sum(vapply(z, function(x) x$kind == "nogo", logical(1)))
    n_ri <- sum(vapply(z, function(x) x$kind == "risk", logical(1)))
    sprintf("%d no-go zone(s), %d risk circle(s) active", n_no, n_ri)
  })

  nogo_sfc <- reactive({
    z <- Filter(function(x) x$kind == "nogo", rv$zones)
    if (length(z) == 0) return(NULL)
    sf::st_sfc(lapply(unname(z), function(x) x$geom), crs = 4326)
  })

  risk_hz <- reactive({
    z <- Filter(function(x) x$kind == "risk", rv$zones)
    if (length(z) == 0) return(empty_hz())
    do.call(rbind, unname(lapply(z, function(x)
      make_hz("User risk circle", x$label, x$lat, x$lon, x$r_km, x$sev, "user"))))
  })

  # ---- custom CSV upload (own hubs / camps) ------------------------------------
  custom_pts <- reactive({
    f <- input$custom_csv
    if (is.null(f)) return(NULL)
    d <- tryCatch(utils::read.csv(f$datapath, stringsAsFactors = FALSE), error = function(e) NULL)
    need <- c("name", "lat", "lon", "type", "tonnes")
    if (is.null(d) || !all(need %in% names(d))) return(NULL)
    d$lat <- suppressWarnings(as.numeric(d$lat))
    d$lon <- suppressWarnings(as.numeric(d$lon))
    d$tonnes <- suppressWarnings(as.numeric(d$tonnes))
    d$type <- tolower(trimws(as.character(d$type)))
    keep <- !is.na(d$lat) & !is.na(d$lon) & !is.na(d$tonnes) & d$tonnes > 0 &
      d$type %in% c("hub", "camp") & d$lat > 5 & d$lat < 38 & d$lon > 67 & d$lon < 98
    d <- d[keep, , drop = FALSE]
    if (nrow(d) == 0) return(NULL)
    nn <- vapply(seq_len(nrow(d)), function(i)
      which.min(haversine_km(d$lon[i], d$lat[i], nodes$lon, nodes$lat)), integer(1))
    d$node <- nodes$id[nn]
    d$snap_km <- haversine_km(d$lon, d$lat, nodes$lon[nn], nodes$lat[nn])
    d
  })

  output$custom_status <- renderText({
    if (is.null(input$custom_csv)) return("No custom file (optional)")
    cp <- custom_pts()
    if (is.null(cp)) return("Could not use the file - need columns name, lat, lon, type, tonnes (India only)")
    sprintf("%d custom point(s) added; each is snapped to the nearest network city", nrow(cp))
  })

  output$dl_template <- downloadHandler(
    filename = function() "custom_points_template.csv",
    content = function(file) {
      utils::write.csv(data.frame(
        name = c("Relief godown, Patna ring road", "Flood camp, Madhubani"),
        lat = c(25.61, 26.35), lon = c(85.10, 86.07),
        type = c("hub", "camp"), tonnes = c(120, 45)), file, row.names = FALSE)
    })

  # ---- all hazards = scenario + live + replay + user circles -----------------------
  all_hz <- reactive({
    live <- if (isTRUE(input$use_live) && !is.null(rv$live)) rv$live$hz else NULL
    hist <- if (isTRUE(input$use_hist) && !is.null(rv$hist)) rv$hist$hz else NULL
    rbind_hz(scenario_hazards(input$scenario), live, hist, risk_hz())
  })

  # ---- the Weighted Risk Index engine ------------------------------------------------
  net <- reactive({
    edge_state(edges, NET$lines, all_hz(), nogo_sfc(),
               wH = input$wH, wR = input$wR, wS = input$wS, lambda = input$lambda,
               auto_block = input$auto_block, block_thr = input$block_thr)
  })

  # ---- the fleet plan ----------------------------------------------------------------
  plan <- reactive({
    st <- net()
    hz <- all_hz()

    Hn <- hazard_exposure(hz, nodes$lon, nodes$lat, nodes$lon, nodes$lat)
    names(Hn) <- nodes$id
    dem_all <- demand_tonnes(nodes, Hn, input$affected_pct, input$kg_pp, input$days)
    names(dem_all) <- nodes$id

    hubs0 <- input$hubs
    camps0 <- input$camps
    supply <- numeric(0)
    demand <- numeric(0)
    if (length(hubs0) > 0) {
      supply <- stats::setNames(round(nodes$stock_t[match(hubs0, nodes$id)] * input$stock_mult), hubs0)
    }
    if (length(camps0) > 0) {
      demand <- stats::setNames(as.numeric(dem_all[camps0]), camps0)
    }
    cp <- custom_pts()
    if (!is.null(cp)) {
      for (k in seq_len(nrow(cp))) {
        id <- cp$node[k]
        t <- round(cp$tonnes[k])
        if (cp$type[k] == "hub") {
          supply[id] <- if (id %in% names(supply)) supply[[id]] + t else t
        } else {
          demand[id] <- if (id %in% names(demand)) demand[[id]] + t else t
        }
      }
    }
    hubs <- names(supply)
    camps <- names(demand)
    validate(need(length(hubs) > 0, "Pick at least one relief hub (Step 2)."),
             need(length(camps) > 0, "Pick at least one affected city (Step 2)."))

    cost <- cost_matrix(NET$graph, st$w_risk, st$blocked, hubs, camps)
    flow <- solve_allocation(cost, as.numeric(supply), as.numeric(demand))
    flow <- matrix(flow, nrow = length(hubs), ncol = length(camps),
                   dimnames = list(hubs, camps))

    rows <- list(); lanes <- list()
    for (i in seq_along(hubs)) {
      for (j in seq_along(camps)) {
        q <- flow[i, j]
        if (q <= 0) next
        r <- route_on(NET$graph, st$w_risk, st$blocked, hubs[i], camps[j])
        if (!r$ok) next
        mt <- route_metrics(r$e, st, edges, input$rs_per_km)
        trips <- ceiling(q / input$truck_cap)
        rows[[length(rows) + 1]] <- data.frame(
          Hub = nodes$name[match(hubs[i], nodes$id)],
          Camp = nodes$name[match(camps[j], nodes$id)],
          Tonnes = q, Trips = trips, Km = round(mt$km), Hours = mt$hours,
          AvgWRI = round(mt$wri_mean, 1), PeakWRI = round(mt$wri_max, 1),
          CostINR = mt$cost_inr * trips,
          Via = paste(nodes$name[match(r$v, nodes$id)], collapse = " > "),
          stringsAsFactors = FALSE)
        lanes[[length(lanes) + 1]] <- list(hub = hubs[i], camp = camps[j], tonnes = q,
                                           v = r$v, e = r$e, hub_pos = i)
      }
    }
    tab <- if (length(rows) > 0) do.call(rbind, rows) else
      data.frame(Hub = character(), Camp = character(), Tonnes = numeric(),
                 Trips = numeric(), Km = numeric(), Hours = numeric(),
                 AvgWRI = numeric(), PeakWRI = numeric(), CostINR = numeric(),
                 Via = character(), stringsAsFactors = FALSE)

    served <- colSums(flow)
    camp_df <- data.frame(
      id = camps, Camp = nodes$name[match(camps, nodes$id)],
      Demand = as.numeric(demand), Delivered = as.numeric(served),
      Unmet = pmax(0, as.numeric(demand) - as.numeric(served)), stringsAsFactors = FALSE)
    camp_df$Pct <- ifelse(camp_df$Demand > 0, 100 * camp_df$Delivered / camp_df$Demand, 100)
    sent <- rowSums(flow)
    hub_df <- data.frame(id = hubs, Hub = nodes$name[match(hubs, nodes$id)],
                         Stock = as.numeric(supply), Sent = as.numeric(sent),
                         Left = pmax(0, as.numeric(supply) - as.numeric(sent)),
                         stringsAsFactors = FALSE)

    list(table = tab, lanes = lanes, camp_df = camp_df, hub_df = hub_df,
         flow = flow, st = st, Hn = Hn, total_trips = sum(tab$Trips))
  })

  # ---- convoy planner (multi-stop VRP) --------------------------------------------------
  convoys <- reactive({
    p <- plan()
    st <- p$st
    flow <- p$flow
    if (sum(flow) <= 0) return(NULL)
    ids <- unique(c(rownames(flow), colnames(flow)))
    Dr <- cost_matrix(NET$graph, st$w_risk, st$blocked, ids, ids)
    Dk <- cost_matrix(NET$graph, st$w_short, st$blocked, ids, ids)
    out <- list()
    for (h in rownames(flow)) {
      q <- stats::setNames(as.numeric(flow[h, ]), colnames(flow))
      q <- q[q > 0 & names(q) != h]
      if (length(q) == 0) next
      res <- plan_convoys(h, q, input$truck_cap, Dr, Dk)
      if (!is.null(res)) out[[length(out) + 1]] <- res
    }
    if (length(out) == 0) return(NULL)
    do.call(rbind, out)
  })

  convoys_display <- reactive({
    d <- convoys()
    if (is.null(d)) {
      return(data.frame("Hub" = character(), "Convoy stops" = character(), "Load (t)" = numeric(),
                        "Trucks" = numeric(), "Km per truck" = numeric(),
                        "Km if 1 truck per camp" = numeric(), "Km saved (%)" = numeric(),
                        check.names = FALSE, stringsAsFactors = FALSE))
    }
    stops <- vapply(strsplit(d$Stops, ">", fixed = TRUE), function(x)
      paste(nodes$name[match(x, nodes$id)], collapse = " > "), character(1))
    data.frame("Hub" = nodes$name[match(d$Hub, nodes$id)], "Convoy stops" = stops,
               "Load (t)" = round(d$Load, 1), "Trucks" = d$Trucks,
               "Km per truck" = round(d$Km), "Km if 1 truck per camp" = round(d$DirectKm),
               "Km saved (%)" = round(100 * (1 - d$Km / pmax(d$DirectKm, 1e-9)), 1),
               check.names = FALSE, stringsAsFactors = FALSE)
  })

  output$cv_tbl <- DT::renderDataTable({
    d <- convoys_display()
    DT::datatable(d, rownames = FALSE, class = "stripe hover",
                  options = list(pageLength = 10, scrollX = TRUE, dom = "tip")) %>%
      DT::formatStyle("Km saved (%)", fontWeight = "bold",
                      color = DT::styleInterval(0.5, c("#6c757d", "#138808")))
  })

  output$vb_cv_trucks <- renderValueBox({
    d <- convoys()
    valueBox(if (is.null(d)) "0" else sum(d$Trucks), "Truck tours needed (convoy plan)",
             icon = icon("truck"), color = "purple")
  })
  output$vb_cv_direct <- renderValueBox({
    valueBox(plan()$total_trips, "Truck trips if each camp gets its own trucks",
             icon = icon("road"), color = "orange")
  })
  output$vb_cv_saved <- renderValueBox({
    d <- convoys()
    v <- if (is.null(d) || sum(d$DirectKm * d$Trucks) <= 0) 0 else
      100 * (1 - sum(d$Km * d$Trucks) / sum(d$DirectKm * d$Trucks))
    valueBox(sprintf("%.0f%%", v), "Distance saved by multi-stop tours",
             icon = icon("percent"), color = "green")
  })

  output$cv_plot <- renderPlotly({
    d <- convoys()
    validate(need(!is.null(d), "No deliveries to plan yet."))
    d$HubName <- nodes$name[match(d$Hub, nodes$id)]
    agg <- stats::aggregate(cbind(Convoy = d$Km * d$Trucks, Direct = d$DirectKm * d$Trucks),
                            by = list(Hub = d$HubName), FUN = sum)
    plot_ly(agg, x = ~Hub, y = ~Direct, type = "bar", name = "One truck per camp (km)",
            marker = list(color = "#f4623a")) %>%
      add_trace(y = ~Convoy, type = "bar", name = "Convoy tours (km)", marker = list(color = "#138808")) %>%
      layout(barmode = "group", xaxis = list(title = ""), yaxis = list(title = "Total km driven"),
             legend = list(orientation = "h"), paper_bgcolor = "rgba(0,0,0,0)",
             plot_bgcolor = "rgba(0,0,0,0)")
  })

  # ---- value boxes -----------------------------------------------------------------------
  output$vb_demand <- renderValueBox({
    p <- plan()
    valueBox(paste0(format(sum(p$camp_df$Demand), big.mark = ",", scientific = FALSE), " t"),
             "Relief demand", icon = icon("users"), color = "red")
  })
  output$vb_supply <- renderValueBox({
    p <- plan()
    valueBox(paste0(format(sum(p$hub_df$Stock), big.mark = ",", scientific = FALSE), " t"),
             "Stock in hubs", icon = icon("truck"), color = "blue")
  })
  output$vb_served <- renderValueBox({
    p <- plan()
    pct <- 100 * sum(p$camp_df$Delivered) / max(1, sum(p$camp_df$Demand))
    valueBox(sprintf("%.0f%%", pct), "Demand deliverable now", icon = icon("percent"),
             color = if (pct >= 95) "green" else if (pct >= 70) "yellow" else "red")
  })
  output$vb_blocked <- renderValueBox({
    st <- net()
    valueBox(paste0(sum(st$blocked), " / ", nrow(edges)), "Road links closed",
             icon = icon("road"), color = "maroon")
  })
  output$vb_trips <- renderValueBox({
    p <- plan()
    rounds <- ceiling(p$total_trips / max(1, input$trucks))
    valueBox(paste0(p$total_trips, " trips"), paste0(input$trucks, " trucks = ", rounds, " round(s)"),
             icon = icon("truck"), color = "purple")
  })
  output$vb_wri <- renderValueBox({
    p <- plan()
    tb <- p$table
    w <- if (nrow(tb) > 0 && sum(tb$Tonnes * tb$Km) > 0)
      sum(tb$Tonnes * tb$Km * tb$AvgWRI) / sum(tb$Tonnes * tb$Km) else 0
    valueBox(sprintf("%.1f / 100", w), "Plan Weighted Risk Index",
             icon = icon("exclamation-triangle"), color = "orange")
  })

  # ---- situation banner -------------------------------------------------------------------
  output$banner <- renderUI({
    hz <- all_hz()
    st <- net()
    p <- tryCatch(plan(), error = function(e) NULL)
    sc <- SCENARIOS[[input$scenario]]$label
    pills <- list(
      span(class = "pill pill-purple", sc),
      span(class = "pill pill-red", sprintf("%d hazard zones", nrow(hz))),
      span(class = "pill pill-orange", sprintf("%d roads closed", sum(st$blocked))))
    if (!is.null(p)) {
      cov <- 100 * sum(p$camp_df$Delivered) / max(1, sum(p$camp_df$Demand))
      pills[[length(pills) + 1]] <- span(class = if (cov >= 95) "pill pill-green" else "pill pill-red",
                                         sprintf("%.0f%% of demand deliverable", cov))
    }
    pills[[length(pills) + 1]] <- if (NET$real_roads)
      span(class = "pill pill-blue", "Real OpenStreetMap roads") else
      span(class = "pill pill-grey", "Corridor network (download real roads in Data & Method)")
    if (!is.null(rv$live)) pills[[length(pills) + 1]] <-
      span(class = "pill pill-green", paste("Live data", rv$live$time))
    if (!is.null(rv$hist)) pills[[length(pills) + 1]] <-
      span(class = "pill pill-purple", paste("Replay:", rv$hist$label))
    tour <- if (HAS_INTRO) actionButton("tour", "Guided tour / गाइड", icon = icon("question-circle"),
                                        class = "btn-saffron btn-sm") else NULL
    div(class = "banner", pills, tour)
  })

  # ---- guided tour (optional package rintrojs) ---------------------------------------------
  observeEvent(input$tour, {
    if (!HAS_INTRO) return()
    steps <- data.frame(
      element = c("#vb_demand", "#steps", "#map", ".sidebar-menu"),
      intro = c("These cards update instantly: relief demand, hub stock, share deliverable, closed roads, truck trips and the plan's Weighted Risk Index.",
                "Work through the four steps: Situation (hazards), Resources (hubs and camps), Risk (how cautious to be) and Danger zones.",
                "Draw a red polygon with the toolbar at the top-left of the map to close roads. Routes and numbers re-calculate immediately.",
                "Open Fleet Plan, Convoy Planner, Route Compare and Hazard Feed for tables, charts and downloads."),
      stringsAsFactors = FALSE)
    tryCatch(rintrojs::introjs(session, options = list(steps = steps, nextLabel = "Next",
                                                       prevLabel = "Back", doneLabel = "Done")),
             error = function(e) NULL)
  })

  # ---- base map -------------------------------------------------------------------------------
  output$map <- renderLeaflet({
    m <- leaflet(options = leafletOptions(minZoom = 4)) %>%
      addProviderTiles("OpenStreetMap.Mapnik", group = "OpenStreetMap") %>%
      addProviderTiles("Esri.WorldStreetMap", group = "Colourful streets") %>%
      addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
      addProviderTiles("OpenTopoMap", group = "Terrain") %>%
      fitBounds(68, 7, 97.5, 35.5) %>%
      addScaleBar("bottomleft") %>%
      addLegend(position = "bottomright", opacity = 0.95,
                colors = c("#2a9d8f", "#e9c46a", "#f4a261", "#e76f51", "#9d0208", "#111111"),
                labels = c("WRI 0-20 (low)", "20-40", "40-60", "60-80", "80-100 (severe)", "Closed road"),
                title = "Road Weighted Risk Index") %>%
      addLayersControl(
        baseGroups = c("OpenStreetMap", "Colourful streets", "Satellite", "Terrain"),
        overlayGroups = c("Road network risk", "Hazards", "Demand heatmap", "Supply heatmap",
                          "Hubs & camps", "Custom points", "Optimised routes", "Danger circles"),
        options = layersControlOptions(collapsed = TRUE)) %>%
      hideGroup("Supply heatmap")
    if (HAS_EXTRAS) m <- tryCatch(leaflet.extras::addFullscreenControl(m), error = function(e) m)
    add_draw_toolbar(m)
  })

  # network risk layer (real OSM geometry when downloaded)
  observe({
    st <- net()
    d <- sf::st_sf(
      data.frame(name = edges$name, road = edges$road, terrain = edges$terrain,
                 km = round(edges$km), wri = st$wri, H = st$H, blocked = st$blocked,
                 stringsAsFactors = FALSE),
      geometry = NET$lines)
    d$popup <- paste0("<b>", d$name, "</b><br>", d$road, " / ", d$terrain,
                      "<br>Length: ", d$km, " km<br>Weighted Risk Index: <b>", round(d$wri, 1),
                      "</b> / 100<br>Hazard exposure: ", round(d$H * 100), "%",
                      ifelse(d$blocked, "<br><b style='color:#d62828'>CLOSED (no-go / severe hazard)</b>", ""))
    open <- d[!d$blocked, ]
    shut <- d[d$blocked, ]
    proxy <- leafletProxy("map") %>% clearGroup("Road network risk")
    if (nrow(open) > 0) {
      proxy <- proxy %>% addPolylines(data = open, color = ~pal_wri(pmin(100, pmax(0, wri))),
                                      weight = 4, opacity = 0.85, popup = ~popup, label = ~name,
                                      group = "Road network risk")
    }
    if (nrow(shut) > 0) {
      proxy %>% addPolylines(data = shut, color = "#111111", weight = 4, opacity = 0.9,
                             dashArray = "8,8", popup = ~popup, label = ~name,
                             group = "Road network risk")
    }
  })

  # hazard layer
  observe({
    hz <- all_hz()
    proxy <- leafletProxy("map") %>% clearGroup("Hazards")
    if (nrow(hz) > 0) {
      hz$popup <- paste0("<b>", hz$label, "</b><br>Source: ", hz$source,
                         "<br>Severity: ", round(hz$severity, 2), "<br>Radius: ", round(hz$radius_km), " km")
      proxy %>% addCircles(data = hz, lng = ~lon, lat = ~lat, radius = ~radius_km * 1000,
                           color = ~pal_hz(severity), fillColor = ~pal_hz(severity),
                           weight = 2, opacity = 0.9, fillOpacity = 0.25,
                           popup = ~popup, label = ~label, group = "Hazards")
    }
  })

  # click-created circles
  observe({
    zs <- Filter(function(x) identical(x$source, "click"), rv$zones)
    proxy <- leafletProxy("map") %>% clearGroup("Danger circles")
    if (length(zs) > 0) {
      d <- sf::st_sf(
        data.frame(kind = unname(vapply(zs, function(x) x$kind, character(1))),
                   label = unname(vapply(zs, function(x) x$label, character(1))),
                   stringsAsFactors = FALSE),
        geometry = sf::st_sfc(lapply(unname(zs), function(x) x$geom), crs = 4326))
      proxy %>% addPolygons(data = d, color = ~ifelse(kind == "nogo", "#d90429", "#f77f00"),
                            fillColor = ~ifelse(kind == "nogo", "#ef233c", "#ffba08"),
                            weight = 2, fillOpacity = 0.35, label = ~label,
                            group = "Danger circles")
    }
  })

  # uploaded custom points
  observe({
    cp <- custom_pts()
    proxy <- leafletProxy("map") %>% clearGroup("Custom points")
    if (!is.null(cp)) {
      proxy %>% addCircleMarkers(data = cp, lng = ~lon, lat = ~lat, radius = 9, weight = 2,
                                 color = "#ffffff",
                                 fillColor = ~ifelse(type == "hub", "#0077b6", "#d00000"),
                                 fillOpacity = 0.95,
                                 label = ~paste0(name, " (", type, ", ", tonnes, " t)"),
                                 popup = ~paste0("<b>", name, "</b><br>", type, ": ", tonnes,
                                                 " t<br>Snapped to ", node, " (", round(snap_km), " km away)"),
                                 group = "Custom points")
    }
  })

  # heat-maps, hubs / camps and routes (all depend on the plan)
  lane_geoms <- reactive({
    p <- plan()
    lanes <- p$lanes
    out <- vector("list", length(lanes))
    snap_ok <- isTRUE(input$snap) && !NET$real_roads
    ng <- nogo_sfc()
    tried_fail <- FALSE
    for (k in seq_along(lanes)) {
      co <- route_xy(lanes[[k]]$v, lanes[[k]]$e, NET$lines, nodes)
      geom <- list(line = co, snapped = FALSE, note = "")
      if (snap_ok && !tried_fail && nrow(co) >= 2) {
        pc <- path_coords(lanes[[k]]$v, nodes)
        key <- paste(round(pc, 3), collapse = ",")
        sn <- snap_cache[[key]]
        if (is.null(sn)) {
          sn <- osrm_snap(pc)
          if (is.null(sn)) tried_fail <- TRUE else assign(key, sn, envir = snap_cache)
        }
        if (!is.null(sn)) {
          crosses <- FALSE
          if (!is.null(ng)) {
            ln <- sf::st_sfc(sf::st_linestring(sn$line), crs = 4326)
            crosses <- isTRUE(any(suppressMessages(sf::st_intersects(ln, ng, sparse = FALSE))))
          }
          if (crosses) {
            geom$note <- "OSRM road geometry touches a no-go zone - corridor shown instead"
          } else {
            geom <- list(line = sn$line, snapped = TRUE,
                         note = sprintf("Road-snapped by OSRM: %.0f km", sn$km))
          }
        }
      }
      out[[k]] <- geom
    }
    out
  })

  observe({
    p <- tryCatch(plan(), error = function(e) NULL)
    proxy <- leafletProxy("map") %>% clearGroup("Demand heatmap") %>% clearGroup("Supply heatmap") %>%
      clearGroup("Hubs & camps")
    if (is.null(p)) return()

    cdf <- p$camp_df
    cpos <- match(cdf$id, nodes$id)
    hdf <- p$hub_df
    hpos <- match(hdf$id, nodes$id)
    proxy <- add_heat(proxy, nodes$lon[cpos], nodes$lat[cpos],
                      pmax(0.15, cdf$Demand / max(1, max(cdf$Demand))),
                      c("#fff3b0", "#ffb703", "#fb5607", "#d00000"), "Demand heatmap")
    proxy <- add_heat(proxy, nodes$lon[hpos], nodes$lat[hpos],
                      pmax(0.15, hdf$Stock / max(1, max(hdf$Stock))),
                      c("#caf0f8", "#48cae4", "#0096c7", "#023e8a"), "Supply heatmap")

    other <- nodes[!(nodes$id %in% c(cdf$id, hdf$id)), ]
    if (nrow(other) > 0) {
      proxy <- proxy %>%
        addCircleMarkers(data = other, lng = ~lon, lat = ~lat, radius = 4, stroke = FALSE,
                         fillColor = "#868e96", fillOpacity = 0.7, label = ~name,
                         popup = ~paste0("<b>", name, "</b>, ", state, "<br>Population ~", pop_lakh, " lakh"),
                         group = "Hubs & camps")
    }

    col <- ifelse(cdf$Pct >= 99, "green", ifelse(cdf$Pct >= 50, "orange", "red"))
    ic <- leaflet::awesomeIcons(icon = "plus", library = "fa", markerColor = col, iconColor = "white")
    proxy <- proxy %>%
      addAwesomeMarkers(lng = nodes$lon[cpos], lat = nodes$lat[cpos], icon = ic,
                        label = paste0(cdf$Camp, ": ", round(cdf$Delivered), "/", cdf$Demand, " t"),
                        popup = paste0("<b>", cdf$Camp, "</b> (affected city)<br>Demand: ", cdf$Demand,
                                       " t<br>Delivered: ", round(cdf$Delivered), " t<br>Unmet: ",
                                       round(cdf$Unmet), " t<br>Local hazard: ", round(p$Hn[cdf$id] * 100), "%"),
                        group = "Hubs & camps")
    hic <- leaflet::awesomeIcons(icon = "truck", library = "fa", markerColor = "blue", iconColor = "white")
    proxy %>%
      addAwesomeMarkers(lng = nodes$lon[hpos], lat = nodes$lat[hpos], icon = hic,
                        label = paste0(hdf$Hub, " hub: ", round(hdf$Sent), "/", hdf$Stock, " t sent"),
                        popup = paste0("<b>", hdf$Hub, "</b> (relief hub)<br>Stock: ", hdf$Stock,
                                       " t<br>Dispatched: ", round(hdf$Sent), " t<br>Left: ", round(hdf$Left), " t"),
                        group = "Hubs & camps")
  })

  observe({
    p <- tryCatch(plan(), error = function(e) NULL)
    proxy <- leafletProxy("map") %>% clearGroup("Optimised routes")
    if (is.null(p) || length(p$lanes) == 0) return()
    gm <- lane_geoms()
    mx <- max(1, max(vapply(p$lanes, function(l) l$tonnes, numeric(1))))
    for (k in seq_along(p$lanes)) {
      l <- p$lanes[[k]]
      co <- gm[[k]]$line
      if (is.null(co) || nrow(co) < 2) next
      col <- LANE_COLS[(l$hub_pos - 1) %% length(LANE_COLS) + 1]
      tip <- sprintf("%s -> %s: %d t, %s", nodes$name[match(l$hub, nodes$id)],
                     nodes$name[match(l$camp, nodes$id)], round(l$tonnes),
                     if (nzchar(gm[[k]]$note)) gm[[k]]$note else "optimised route")
      proxy <- proxy %>%
        addPolylines(lng = co[, 1], lat = co[, 2], color = "#ffffff", weight = 10,
                     opacity = 0.9, group = "Optimised routes") %>%
        addPolylines(lng = co[, 1], lat = co[, 2], color = col,
                     weight = 4 + 6 * l$tonnes / mx, opacity = 0.95, label = tip,
                     popup = tip, group = "Optimised routes")
    }
  })

  # ---- fleet tab -----------------------------------------------------------------------------------
  plan_display <- reactive({
    tb <- plan()$table
    data.frame(
      "From hub" = tb$Hub, "To city" = tb$Camp, "Tonnes" = round(tb$Tonnes),
      "Truck trips" = tb$Trips, "Distance (km)" = tb$Km, "ETA" = fmt_hours(tb$Hours),
      "Avg WRI" = tb$AvgWRI, "Peak WRI" = tb$PeakWRI,
      "Round-trip cost" = fmt_inr(tb$CostINR), "Route" = tb$Via,
      check.names = FALSE, stringsAsFactors = FALSE)
  })

  output$plan_tbl <- DT::renderDataTable({
    d <- plan_display()
    DT::datatable(d, rownames = FALSE, class = "stripe hover",
                  options = list(pageLength = 8, scrollX = TRUE, dom = "tip")) %>%
      DT::formatStyle("Peak WRI",
                      backgroundColor = DT::styleInterval(c(25, 50, 70),
                                                          c("#d8f3dc", "#fff3bf", "#ffd8a8", "#ffc9c9")))
  })

  output$dl_plan <- downloadHandler(
    filename = function() paste0("relief_plan_", format(Sys.Date(), "%Y%m%d"), ".csv"),
    content = function(file) utils::write.csv(plan_display(), file, row.names = FALSE, fileEncoding = "UTF-8")
  )

  output$dl_report <- downloadHandler(
    filename = function() paste0("situation_report_", format(Sys.Date(), "%Y%m%d"), ".html"),
    content = function(file) {
      p <- plan()
      st <- net()
      hz <- all_hz()
      cov <- 100 * sum(p$camp_df$Delivered) / max(1, sum(p$camp_df$Demand))
      kp <- c(sprintf("%s t", format(sum(p$camp_df$Demand), big.mark = ",", scientific = FALSE)),
              sprintf("%s t", format(sum(p$hub_df$Stock), big.mark = ",", scientific = FALSE)),
              sprintf("%.0f%%", cov), as.character(sum(st$blocked)), as.character(p$total_trips))
      names(kp) <- c("Relief demand", "Stock in hubs", "Demand deliverable", "Road links closed", "Truck trips")
      hz_df <- data.frame(Source = hz$source, Hazard = hz$label, Severity = round(hz$severity, 2),
                          "Radius km" = round(hz$radius_km), check.names = FALSE, stringsAsFactors = FALSE)
      cov_df <- data.frame(City = p$camp_df$Camp, "Demand t" = p$camp_df$Demand,
                           "Delivered t" = round(p$camp_df$Delivered), "Unmet t" = round(p$camp_df$Unmet),
                           check.names = FALSE, stringsAsFactors = FALSE)
      build_report_html(
        "ReliefRoute India - Situation Report",
        meta = list(Generated = format(Sys.time(), "%d %b %Y %I:%M %p", tz = "Asia/Kolkata"),
                    Scenario = SCENARIOS[[input$scenario]]$label,
                    "Risk aversion" = input$lambda,
                    "Road data" = if (NET$real_roads) "OpenStreetMap (OSRM)" else "corridor network"),
        kpis = kp,
        tables = list("Demand coverage" = cov_df, "Fleet plan" = plan_display(),
                      "Convoy plan" = convoys_display(), "Hazards in force" = hz_df),
        file = file)
    })

  output$plot_cov <- renderPlotly({
    cd <- plan()$camp_df
    plot_ly(cd, x = ~Camp, y = ~Delivered, type = "bar", name = "Delivered (t)",
            marker = list(color = "#2a9d8f")) %>%
      add_trace(y = ~Unmet, type = "bar", name = "Unmet (t)", marker = list(color = "#e63946")) %>%
      layout(barmode = "stack", xaxis = list(title = ""), yaxis = list(title = "Tonnes"),
             legend = list(orientation = "h"), paper_bgcolor = "rgba(0,0,0,0)",
             plot_bgcolor = "rgba(0,0,0,0)")
  })

  output$plot_hub <- renderPlotly({
    hd <- plan()$hub_df
    plot_ly(hd, x = ~Hub, y = ~Sent, type = "bar", name = "Dispatched (t)",
            marker = list(color = "#ff9933")) %>%
      add_trace(y = ~Left, type = "bar", name = "Remaining (t)", marker = list(color = "#118ab2")) %>%
      layout(barmode = "stack", xaxis = list(title = ""), yaxis = list(title = "Tonnes"),
             legend = list(orientation = "h"), paper_bgcolor = "rgba(0,0,0,0)",
             plot_bgcolor = "rgba(0,0,0,0)")
  })

  # ---- compare tab --------------------------------------------------------------------------------------
  cmp <- reactive({
    req(input$cmp_from, input$cmp_to)
    st <- net()
    none <- rep(FALSE, nrow(edges))
    modes <- list(
      list(name = "GPS-style fastest (ignores hazards)", col = "#6c757d", w = st$w_fast, blocked = none),
      list(name = "Closure-aware fastest", col = "#1d70b8", w = st$time_h, blocked = st$blocked),
      list(name = "WRI-optimised (this app)", col = "#2a9d8f", w = st$w_risk, blocked = st$blocked))
    lapply(modes, function(m) {
      r <- route_on(NET$graph, m$w, m$blocked, input$cmp_from, input$cmp_to)
      if (!r$ok) return(list(name = m$name, col = m$col, ok = FALSE))
      list(name = m$name, col = m$col, ok = TRUE, v = r$v, e = r$e,
           mt = route_metrics(r$e, st, edges, input$rs_per_km))
    })
  })

  output$cmp_tbl <- DT::renderDataTable({
    cm <- cmp()
    rows <- lapply(cm, function(x) {
      if (!x$ok) {
        data.frame(Strategy = x$name, Distance = "-", ETA = "-", AvgWRI = NA_real_, PeakWRI = NA_real_,
                   Exposed = NA_integer_, Closed = NA_integer_, Cost = "no safe route",
                   stringsAsFactors = FALSE)
      } else {
        data.frame(Strategy = x$name, Distance = sprintf("%.0f km", x$mt$km), ETA = fmt_hours(x$mt$hours),
                   AvgWRI = round(x$mt$wri_mean, 1), PeakWRI = round(x$mt$wri_max, 1),
                   Exposed = as.integer(x$mt$exposed), Closed = as.integer(x$mt$blocked_hit),
                   Cost = fmt_inr(x$mt$cost_inr), stringsAsFactors = FALSE)
      }
    })
    d <- do.call(rbind, rows)
    names(d) <- c("Strategy", "Distance", "ETA", "Avg WRI", "Peak WRI",
                  "Hazard-exposed links", "Closed links crossed", "Round-trip cost")
    DT::datatable(d, rownames = FALSE, options = list(dom = "t", scrollX = TRUE, pageLength = 5)) %>%
      DT::formatStyle("Closed links crossed",
                      color = DT::styleInterval(0, c("#2a9d8f", "#d62828")), fontWeight = "bold")
  })

  output$cmp_plot <- renderPlotly({
    cm <- cmp()
    ok <- Filter(function(x) x$ok, cm)
    validate(need(length(ok) > 0, "No route exists between these cities under the current closures."))
    d <- data.frame(Strategy = vapply(ok, function(x) x$name, character(1)),
                    WRI = vapply(ok, function(x) x$mt$wri_mean, numeric(1)),
                    col = vapply(ok, function(x) x$col, character(1)), stringsAsFactors = FALSE)
    plot_ly(d, x = ~Strategy, y = ~WRI, type = "bar", marker = list(color = d$col)) %>%
      layout(yaxis = list(title = "Average Weighted Risk Index"), xaxis = list(title = ""),
             paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)")
  })

  output$cmp_story <- renderUI({
    cm <- cmp()
    g <- cm[[1]]; w <- cm[[3]]
    if (!isTRUE(g$ok)) return(div(class = "hint", "No route exists between these cities (all corridors closed)."))
    txt <- sprintf("GPS-style route crosses %d closed link(s) and %d hazard-exposed link(s). ",
                   g$mt$blocked_hit, g$mt$exposed)
    if (isTRUE(w$ok)) {
      dwri <- 100 * (g$mt$wri_mean - w$mt$wri_mean) / max(0.1, g$mt$wri_mean)
      dtime <- 100 * (w$mt$hours - g$mt$hours) / max(0.1, g$mt$hours)
      txt <- paste0(txt, sprintf("The WRI-optimised route cuts average risk by %.0f%% for %+.0f%% travel time and crosses %d closed link(s).",
                                 dwri, dtime, w$mt$blocked_hit))
    } else {
      txt <- paste0(txt, "No hazard-free route exists - reduce no-go zones or adjust risk settings.")
    }
    div(class = "status-pill", style = "font-size:14px; padding:8px 14px;", txt)
  })

  output$map_cmp <- renderLeaflet({
    cm <- cmp()
    hz <- all_hz()
    m <- leaflet() %>%
      addProviderTiles("OpenStreetMap.Mapnik") %>%
      fitBounds(68, 7, 97.5, 35.5)
    if (nrow(hz) > 0) {
      m <- m %>% addCircles(data = hz, lng = ~lon, lat = ~lat, radius = ~radius_km * 1000,
                            color = ~pal_hz(severity), fillColor = ~pal_hz(severity),
                            weight = 1, fillOpacity = 0.2, label = ~label)
    }
    ng <- nogo_sfc()
    if (!is.null(ng)) {
      m <- tryCatch(
        m %>% addPolygons(data = sf::st_sf(geometry = ng), color = "#d90429", weight = 2, fillOpacity = 0.3),
        error = function(e) m)
    }
    widths <- c(11, 7, 4)
    for (k in seq_along(cm)) {
      x <- cm[[k]]
      if (!isTRUE(x$ok)) next
      co <- route_xy(x$v, x$e, NET$lines, nodes)
      if (nrow(co) < 2) next
      m <- m %>% addPolylines(lng = co[, 1], lat = co[, 2], color = x$col, weight = widths[k],
                              opacity = 0.85, label = x$name)
    }
    a <- match(c(input$cmp_from, input$cmp_to), nodes$id)
    m %>% addCircleMarkers(lng = nodes$lon[a], lat = nodes$lat[a], radius = 8, color = "#222",
                           fillColor = c("#06d6a0", "#ef476f"), fillOpacity = 1,
                           label = nodes$name[a], labelOptions = labelOptions(permanent = TRUE)) %>%
      addLegend("bottomleft", colors = vapply(cm, function(x) x$col, character(1)),
                labels = vapply(cm, function(x) x$name, character(1)), title = "Strategy")
  })

  # risk-aversion sweep (sensitivity analysis)
  sweep_df <- reactive({
    req(input$cmp_from, input$cmp_to)
    st <- net()
    rows <- lapply(0:10, function(l) {
      w <- st$time_h * (1 + l * st$wri / 100 * CFG$wri_cost_factor)
      r <- route_on(NET$graph, w, st$blocked, input$cmp_from, input$cmp_to)
      if (!r$ok) return(NULL)
      mt <- route_metrics(r$e, st, edges, input$rs_per_km)
      data.frame(lambda = l, km = mt$km, wri = mt$wri_mean, stringsAsFactors = FALSE)
    })
    rows <- Filter(Negate(is.null), rows)
    if (length(rows) == 0) return(NULL)
    do.call(rbind, rows)
  })

  output$sweep_plot <- renderPlotly({
    d <- sweep_df()
    validate(need(!is.null(d), "No route exists between these cities under the current closures."))
    plot_ly(d, x = ~lambda, y = ~km, type = "scatter", mode = "lines+markers",
            name = "Distance (km)", line = list(color = "#f4623a"), marker = list(color = "#f4623a")) %>%
      add_trace(y = ~wri, type = "scatter", mode = "lines+markers", name = "Average WRI",
                yaxis = "y2", line = list(color = "#138808"), marker = list(color = "#138808")) %>%
      layout(xaxis = list(title = "Risk aversion lambda (0 = GPS-like, 10 = safest)"),
             yaxis = list(title = "Distance (km)"),
             yaxis2 = list(title = "Average WRI", overlaying = "y", side = "right"),
             legend = list(orientation = "h"), paper_bgcolor = "rgba(0,0,0,0)",
             plot_bgcolor = "rgba(0,0,0,0)")
  })

  # ---- hazard tab -----------------------------------------------------------------------------------------
  output$vb_hz_n <- renderValueBox({
    valueBox(nrow(all_hz()), "Active hazard zones", icon = icon("exclamation-triangle"), color = "red")
  })
  output$vb_hz_rain <- renderValueBox({
    r <- rv$live$rain
    h <- rv$hist$rain
    v <- if (!is.null(h)) sprintf("%.0f mm", max(h$mm, na.rm = TRUE)) else
      if (!is.null(r)) sprintf("%.0f mm", max(r$mm, na.rm = TRUE)) else "n/a"
    lab <- if (!is.null(h)) "Peak rain in replayed event (ERA5)" else "Peak forecast rain (3-day, any city)"
    valueBox(v, lab, icon = icon("cloud"), color = "aqua")
  })
  output$vb_hz_zones <- renderValueBox({
    valueBox(length(rv$zones), "User-defined zones", icon = icon("map"), color = "purple")
  })
  output$hz_tbl <- DT::renderDataTable({
    hz <- all_hz()
    d <- data.frame(Source = hz$source, Hazard = hz$label, Severity = round(hz$severity, 2),
                    "Radius km" = round(hz$radius_km), Lat = round(hz$lat, 2), Lon = round(hz$lon, 2),
                    check.names = FALSE, stringsAsFactors = FALSE)
    DT::datatable(d, rownames = FALSE, options = list(pageLength = 8, scrollX = TRUE, dom = "tip")) %>%
      DT::formatStyle("Severity", background = DT::styleColorBar(c(0, 1), "#ff9f9f"),
                      backgroundSize = "100% 80%", backgroundRepeat = "no-repeat",
                      backgroundPosition = "center")
  })
  output$live_msgs <- renderUI({
    msgs <- c(rv$live$msgs, rv$hist$msg)
    if (length(msgs) == 0) return(div(class = "hint", "Press 'Fetch live hazards' or 'Load historical rainfall' on the Command Map tab."))
    tags$ul(lapply(msgs, tags$li))
  })
  output$rain_plot <- renderPlotly({
    r <- if (!is.null(rv$hist)) rv$hist$rain else rv$live$rain
    validate(need(!is.null(r), "Rain data appears after fetching live or historical data."))
    r <- r[order(-r$mm), ][seq_len(min(12, nrow(r))), ]
    r$name <- factor(r$name, levels = rev(r$name))
    plot_ly(r, x = ~mm, y = ~name, type = "bar", orientation = "h",
            marker = list(color = ~mm, colorscale = list(c(0, "#a8dadc"), c(1, "#1d3557")))) %>%
      layout(xaxis = list(title = "Max daily rain (mm)"), yaxis = list(title = ""),
             paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)")
  })

  # ---- real road download (OSRM) ---------------------------------------------------------------------------
  output$road_status <- renderText({
    if (NET$real_roads) "REAL OpenStreetMap road geometry is loaded (data/osrm_edges.rds)."
    else "Using straight corridor lines. Click the button to download real roads (needs internet)."
  })

  observeEvent(input$build_roads, {
    res <- NULL
    withProgress(message = "Downloading real road geometry from OSRM ...", value = 0, {
      res <- tryCatch(
        build_osrm_edges(edges, file = file.path("data", "osrm_edges.rds"),
                         progress = function(i, n, what) incProgress(1 / n, detail = what)),
        error = function(e) list(ok = FALSE, n_ok = 0, n = nrow(edges)))
    })
    if (isTRUE(res$ok)) {
      showModal(modalDialog(
        title = "Real roads downloaded",
        sprintf("%d of %d roads saved to data/osrm_edges.rds. Close the app and run it again to use real OpenStreetMap roads.",
                res$n_ok, res$n),
        easyClose = TRUE))
    } else {
      showModal(modalDialog(
        title = "Could not download roads",
        "The public OSRM server was not reachable (or rate-limited). Check your internet connection and try again later.",
        easyClose = TRUE))
    }
  })

  # ---- data tables ---------------------------------------------------------------------------------------------
  output$tbl_cfg <- DT::renderDataTable({
    u <- unlist(CFG)
    DT::datatable(data.frame(Constant = names(u), Value = as.numeric(u), stringsAsFactors = FALSE),
                  rownames = FALSE, options = list(pageLength = 8, scrollX = TRUE, dom = "ftip"))
  })
  output$tbl_nodes <- DT::renderDataTable(
    DT::datatable(nodes, rownames = FALSE, options = list(pageLength = 6, scrollX = TRUE, dom = "ftip")))
  output$tbl_edges <- DT::renderDataTable(
    DT::datatable(edges[, c("from", "to", "road", "terrain", "vuln", "security", "km", "speed")],
                  rownames = FALSE, options = list(pageLength = 6, scrollX = TRUE, dom = "ftip")) %>%
      DT::formatRound(c("km", "speed"), 1))
}

shinyApp(ui, server)
