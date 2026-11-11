test_that("data are consistent", {
  expect_equal(nrow(nodes), 48)
  expect_equal(nrow(edges), 69)
  expect_true(igraph::is_connected(NET$graph))
  expect_false(anyNA(edges$km))
})

test_that("geometry helpers work", {
  d <- haversine_km(77.209, 28.6139, 72.8777, 19.076)   # Delhi - Mumbai
  expect_gt(d, 1100); expect_lt(d, 1200)
  expect_lt(abs(pt_seg_km(0, 0, -1, 1, 1, 1) - 110.57), 1)
  expect_equal(fmt_inr(1234567), "₹12,34,567")
  expect_equal(fmt_hours(30), "1 d 6 h")
  poly <- circle_polygon(85, 25, 30)
  expect_true(inherits(poly, "POLYGON"))
})

test_that("Weighted Risk Index: GPS-style route crosses a closed link, WRI route does not", {
  hz <- scenario_hazards("bihar_assam")
  st <- edge_state(edges, NET$lines, hz, NULL, wH = 8, wR = 4, wS = 3, lambda = 5,
                   auto_block = TRUE, block_thr = 0.85)
  none <- rep(FALSE, nrow(edges))
  gps  <- route_on(NET$graph, st$w_fast, none, "DEL", "GHY")
  safe <- route_on(NET$graph, st$w_risk, st$blocked, "DEL", "GHY")
  expect_true(gps$ok); expect_true(safe$ok)
  expect_true(any(st$blocked[gps$e]))
  expect_false(any(st$blocked[safe$e]))
  expect_gt(sum(edges$km[safe$e]), sum(edges$km[gps$e]))
  xy <- route_xy(safe$v, safe$e, NET$lines, nodes)
  expect_equal(ncol(xy), 2)
  expect_gte(nrow(xy), length(safe$v))
})

test_that("a drawn no-go polygon closes every road touching it", {
  zone <- sf::st_sfc(circle_polygon(85.1376, 25.5941, 30), crs = 4326)
  st <- edge_state(edges, NET$lines, empty_hz(), zone, 8, 4, 3, 5, FALSE, 0.85)
  touch <- edges$from == "PAT" | edges$to == "PAT"
  expect_true(all(st$blocked[touch]))
  expect_false(any(st$blocked[!touch]))
})

test_that("transportation problem respects supply and demand", {
  cost <- matrix(c(1, 5, 4, 2), 2, 2, dimnames = list(c("A", "B"), c("X", "Y")))
  fl <- solve_allocation(cost, supply = c(100, 50), demand = c(80, 60))
  expect_true(all(colSums(fl) <= c(80, 60)))
  expect_true(all(rowSums(fl) <= c(100, 50)))
  expect_equal(sum(fl), 140)
})

test_that("unreachable demand is reported, not invented", {
  cost <- matrix(c(Inf, 3), 1, 2, dimnames = list("A", c("X", "Y")))
  fl <- solve_allocation(cost, supply = 100, demand = c(40, 40))
  expect_equal(fl[1, "X"], 0)
  expect_equal(fl[1, "Y"], 40)
})

test_that("Clarke-Wright combines nearby stops within capacity", {
  pos <- c(10, 12, 30, 32)
  cc <- abs(outer(pos, pos, "-"))
  tours <- clarke_wright(pos, cc, c(3, 3, 3, 3), 6)
  expect_equal(length(tours), 2)
  expect_true(all(vapply(tours, function(t) t$load <= 6, logical(1))))
  expect_equal(sort(unlist(lapply(tours, function(t) t$stops))), 1:4)
})

test_that("rain JSON parsing handles nulls and single locations", {
  js <- list(daily = list(precipitation_sum = list(1, NULL, 80)))
  one <- nodes[1, ]
  r <- rain_from_json(js, one)
  expect_equal(r$mm, 80)
  hz <- rain_to_hz(r, "test", "live")
  expect_equal(nrow(hz), 1)
  expect_lte(hz$severity, 1)
})

test_that("report HTML is written", {
  f <- tempfile(fileext = ".html")
  build_report_html("T", list(a = 1), c(Demand = "5 t"),
                    list(Tab = data.frame(x = 1:2, y = c("a", "b"))), f)
  expect_true(file.exists(f))
  expect_true(any(grepl("<table", readLines(f, warn = FALSE))))
})
