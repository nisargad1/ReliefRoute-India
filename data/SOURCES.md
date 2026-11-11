# Data provenance

| File / feed | What it holds | Origin | Status |
|---|---|---|---|
| `india_nodes.csv` | 48 cities: lat/lon, population (lakh), hub stock | Coordinates and rounded Census-2011 city populations entered manually | **Verify against censusindia.gov.in before submission**; `stock_t` is an illustrative assumption |
| `india_roads.csv` | 69 highway corridors: class, terrain, vulnerability, security | Corridors follow major National/State Highways; `vuln` and `security` are modelling assumptions | Illustrative - replace with NDMA/SDMA data |
| `osrm_edges.rds` (created in-app) | Real road geometry, km and travel time | OpenStreetMap via the public OSRM server | Real data, generated on your machine |
| Rain forecast | 3-day rainfall per city | Open-Meteo forecast API | Live |
| River flood signal | GloFAS river-discharge forecast vs 30-day median | Open-Meteo Flood API | Live |
| Historical replay | Real past rainfall (ERA5 reanalysis, 0.25 deg) | Open-Meteo Historical API | Real; coarse resolution smooths extremes |
| Earthquakes | M4+ in the last 14 days, India region | USGS Earthquake Hazards API | Live |
| Natural events | Floods, storms, landslides, wildfires | NASA EONET v3 | Live |
