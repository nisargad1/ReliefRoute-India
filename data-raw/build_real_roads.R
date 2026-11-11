# Run from the project root:   source("data-raw/build_real_roads.R")
# Downloads real road geometry / distance / time (OpenStreetMap via OSRM) once.
suppressMessages(sf::sf_use_s2(FALSE))
source("helpers/geo.R", encoding = "UTF-8")
source("helpers/hazards.R", encoding = "UTF-8")
source("helpers/config.R", encoding = "UTF-8")
source("helpers/routing.R", encoding = "UTF-8")
source("helpers/osrm.R", encoding = "UTF-8")
net <- load_network("data", use_osrm = FALSE)
res <- build_osrm_edges(net$edges, "data/osrm_edges.rds",
                        progress = function(i, n, what) message(sprintf("[%d/%d] %s", i, n, what)))
print(res)
