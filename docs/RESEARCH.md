# Research note - Dynamic Refugee & Humanitarian Supply-Chain Router

## 1. The real-world problem

After floods, cyclones, earthquakes or conflict, a relief convoy's best route changes hour by hour: bridges fail,
roads flood or slide, security situations shift, and rain keeps falling on the same corridors. Humanitarian
logistics also differs from commercial logistics:

* **Objective** - deliver where need is highest and the route is *survivable*, not simply minimise time or fuel.
* **Information** - road status is partial, local and changing; official bulletins (NDMA, SDMA, IMD, CWC) are not
  machine-routable by default.
* **Decisions are joint** - which hub serves which camp (fleet distribution) and which road each truck takes are
  coupled; closing one bridge changes the whole allocation.
* **Scale of the cost** - logistics is often quoted as the largest share of disaster-relief spending
  (a figure commonly attributed to Van Wassenhove, 2006, "Humanitarian aid logistics: supply chain management in high gear").

India is a strong use-case: monsoon flooding of the Ganga-Brahmaputra basins (Bihar, Assam, North Bengal),
cyclones on the Odisha / Andhra coast, Himalayan landslides and cloudbursts, and Western-Ghats landslides.
IMD classifies rainfall in 24 h as *heavy* (64.5-115.5 mm), *very heavy* (115.6-204.4 mm) and *extremely heavy* (>204.4 mm);
the app uses 115.6 mm as the "severity = 1" reference for rainfall hazards.

## 2. What exists today (and where it stops)

| Tool | What it does well | Limitation for dynamic humanitarian fleets |
|---|---|---|
| Google Maps / Routes API | Excellent live car traffic | Route modifiers are limited to features such as avoid tolls / highways / ferries; no user-defined danger polygons, no risk metric, no fleet allocation ([docs](https://developers.google.com/maps/documentation/routes/route-modifiers)) |
| OSRM | Very fast, open | Graph is pre-processed; ad-hoc blocking zones are awkward (discussed on the OSRM mailing list: [thread](https://lists.openstreetmap.org/pipermail/osrm-talk/2020-August/001890.html)) |
| openrouteservice (ORS) | `avoid_polygons` option; HeiGIT work on disaster routing | Polygon avoidance is binary (avoid / don't) and community threads report cases where routes still clip polygons ([example](https://ask.openrouteservice.org/t/cant-avoid-polygons-the-rendered-route-sometimes-doesnt-avoid-given-polygons/5620)); no multi-depot allocation |
| GraphHopper | Custom models with areas | Requires server-side configuration; no built-in supply-demand view ([forum](https://discuss.graphhopper.com/t/how-many-regions-does-the-custom-model-supports/8990)) |
| HeiGIT dynamic humanitarian routing + WFP Logistics Cluster LogIE | Streaming graph updates; mission-specific road/bridge/port status | Proof-of-concept / institutional platform, not a teachable open R tool ([article](https://heigit.org/rethinking-humanitarian-routing-when-every-minute-and-mile-matter)) |
| ORS + Copernicus EMS flood extents | Flood-aware routing special solution ([HeiGIT](https://heigit.org/routenplanung-im-uberflutungsgebiet-openrouteservice-nutzt-copernicus-ems-flut-daten-in-spezieller-losung-2/)) | Built for specific activations in Europe-centric workflows |
| India: NDMA / NDEM, Bhuvan, India-WRIS, IMD | Authoritative hazard and flood data ([NDEM brochure](https://www.nrsc.gov.in/sites/default/files/pdf/Brochures/NDEM_v5_brochure_lite.pdf)) | Map viewers and bulletins; not integrated with fleet routing or allocation |

## 3. The gap this project fills

1. **Risk is a cost, not just a wall.** A road can be open but dangerous. The *Weighted Risk Index* turns hazard
   exposure, structural vulnerability and access constraints into a continuous penalty with a user-controlled
   risk-aversion parameter (lambda).
2. **Zones are drawn by the user in seconds.** Field teams can sketch a polygon from a radio report; the graph is
   re-cut and plans recomputed immediately (no re-processing).
3. **Routes + allocation together.** The plan is not just a polyline: a transportation LP assigns tonnes from hubs to
   camps using the risk-weighted costs, reports unmet demand, truck trips, ETA and rupee cost.
4. **Demand-aware.** Demand grows with local hazard exposure; supply and demand are shown as heat-maps.
5. **Explainable.** A comparison tab shows *GPS-style fastest* vs *closure-aware fastest* vs *WRI-optimised* for the same
   origin / destination, with the number of closed or exposed links each crosses.
6. **Open and teachable in R**, bilingual (English / Hindi), runnable on a laptop with free data.

## 4. Method summary

1. Network: 48 cities x 69 highway corridors (CSV) -> `sf` lines + `igraph` graph. Length = great-circle x terrain
   circuity (1.20-1.45); loaded-truck speed 55 km/h NH, 40 km/h SH, reduced on hills / floodplains.
2. Hazards: rows of (lat, lon, radius, severity). Sources: Open-Meteo 3-day rainfall forecast (>=30 mm/day), USGS
   M4+ earthquakes (14 days), NASA EONET open events (floods, severe storms, landslides, wildfires), simulated
   scenarios, and user risk circles. Exposure of a segment = severity x (1 - 0.6 x distance/radius) inside the radius.
3. WRI and cost as in the README; roads intersecting no-go polygons or with hazard >= threshold are deleted.
4. Dijkstra (`igraph::shortest_paths`) for routes; `lpSolve::lp.transport` for allocation, with a dummy supplier
   so unreachable / unsupplied demand is reported rather than hidden.
5. Demand (tonnes) = population x affected% x (1 + 1.5 x hazard) x kg/person/day x days / 1000.

## 5. Validation approach and limits

* `tests/testthat/` checks data integrity, geometry helpers, that a GPS-style route crosses a closed link where the
  WRI route does not, that a drawn polygon closes the right roads, and the allocation constraints.
* Honest limits: corridor graph (not full OSM), illustrative stock / vulnerability / security values, simplified
  hazard-to-speed relation, no vehicle-routing time windows. Future work: OSM-based graph via `osmdata`/`dodgr`,
  CWC / India-WRIS gauges, IMD district warnings, multi-vehicle VRP, bridge-level status, user CSV upload.

## 6. Data sources

* Open-Meteo forecast API (free for non-commercial use, CC BY 4.0) - https://open-meteo.com/en/docs
* USGS Earthquake Hazards Program API - https://earthquake.usgs.gov/fdsnws/event/1/
* NASA EONET v3 - https://eonet.gsfc.nasa.gov/docs/v3
* Census of India 2011 (rounded city populations) - https://censusindia.gov.in / https://data.gov.in
* OpenStreetMap contributors; OSRM demo server (optional road snapping)
* R packages: shiny, shinydashboard, leaflet, leaflet.extras, sf, igraph, lpSolve, httr, jsonlite, DT, plotly
