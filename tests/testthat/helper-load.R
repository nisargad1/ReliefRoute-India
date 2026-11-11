# Loads the project code for the tests (works from RStudio or CI).
suppressMessages(sf::sf_use_s2(FALSE))
.root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
for (.f in c("geo", "config", "hazards", "routing", "osrm", "vrp", "report")) {
  source(file.path(.root, "helpers", paste0(.f, ".R")), encoding = "UTF-8")
}
NET <- load_network(file.path(.root, "data"), use_osrm = FALSE)
nodes <- NET$nodes
edges <- NET$edges
