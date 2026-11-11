# =============================================================================
#  helpers/report.R  -  one-page situation report (self-contained HTML that
#  can be printed to PDF from the browser: Ctrl+P -> Save as PDF)
# =============================================================================
html_table <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(htmltools::tags$p("No data."))
  head <- htmltools::tags$tr(lapply(names(df), htmltools::tags$th))
  body <- lapply(seq_len(nrow(df)), function(i) {
    htmltools::tags$tr(lapply(df[i, , drop = FALSE], function(v) htmltools::tags$td(as.character(v))))
  })
  htmltools::tags$table(class = "t", htmltools::tags$thead(head), htmltools::tags$tbody(body))
}

build_report_html <- function(title, meta, kpis, tables, file) {
  css <- "
  body{font-family:Segoe UI,Arial,sans-serif;margin:32px;color:#222}
  h1{background:linear-gradient(90deg,#ff9933,#6a4c93,#138808);color:#fff;padding:14px 18px;border-radius:8px}
  h2{color:#6a4c93;border-bottom:2px solid #ff9933;padding-bottom:4px;margin-top:26px}
  .kpis{display:flex;flex-wrap:wrap;gap:10px;margin:14px 0}
  .kpi{flex:1 1 150px;background:#f6f3ff;border-left:5px solid #ff9933;border-radius:6px;padding:10px}
  .kpi b{display:block;font-size:22px;color:#2b1b5a}
  table.t{border-collapse:collapse;width:100%;font-size:12.5px}
  table.t th{background:#2b1b5a;color:#fff;text-align:left;padding:6px}
  table.t td{border-bottom:1px solid #ddd;padding:5px}
  .note{color:#666;font-size:12px;margin-top:28px}
  @media print{body{margin:10mm}}"
  kp <- lapply(seq_along(kpis), function(i) {
    htmltools::tags$div(class = "kpi", htmltools::tags$b(kpis[[i]]), names(kpis)[i])
  })
  sections <- lapply(names(tables), function(nm) {
    htmltools::tagList(htmltools::tags$h2(nm), html_table(tables[[nm]]))
  })
  page <- htmltools::tags$html(
    htmltools::tags$head(htmltools::tags$meta(charset = "utf-8"),
                         htmltools::tags$title(title),
                         htmltools::tags$style(htmltools::HTML(css))),
    htmltools::tags$body(
      htmltools::tags$h1(title),
      htmltools::tags$p(paste(names(meta), unlist(meta), sep = ": ", collapse = "  |  ")),
      htmltools::tags$div(class = "kpis", kp),
      sections,
      htmltools::tags$p(class = "note",
        "Educational prototype (ReliefRoute India). Figures are model outputs, not official advisories. ",
        "Use NDMA / SDMA / IMD guidance for real decisions. Emergency 112, disaster helpline 1078.")))
  writeLines(enc2utf8(paste0("<!DOCTYPE html>\n", as.character(page))), file, useBytes = TRUE)
  invisible(file)
}
