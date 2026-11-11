# Run ONCE (RStudio: open file -> Source) if you prefer to install packages manually.
# app.R also installs anything missing automatically on first run.
pkgs <- c("shiny", "shinydashboard", "leaflet", "leaflet.extras", "sf", "igraph",
          "lpSolve", "DT", "plotly", "httr", "jsonlite", "htmltools", "rintrojs", "testthat")
missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
if (!requireNamespace("leaflet.extras", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_github("bhaskarvk/leaflet.extras")
}
message("Done. Now open app.R and click 'Run App'.")
