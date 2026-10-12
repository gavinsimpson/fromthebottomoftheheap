#!/usr/bin/env Rscript

source("scripts/posts.R")
source("scripts/build.R")
assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}
fixture <- tempfile("focused-build-")
dir.create(fixture)
dir.create(file.path(fixture, "_site"))
dir.create(file.path(fixture, ".quarto", "listing"), recursive = TRUE)
post <- "2026/01/01/example/index.qmd"
writeLines(c("---", "listing:", "  contents:", paste0("    - ", post), "---"),
  file.path(fixture, "index.qmd"))
before <- archive_fingerprints(fixture)
for (path in c("index.html", "search.json", "sitemap.xml", "listings.json")) {
  writeLines("fixture", file.path(fixture, "_site", path))
}
cache <- file.path(fixture, ".quarto", "listing", "listing-cache.json")
write_cache <- function(contents) jsonlite::write_json(
  list(listingMap = list(index.qmd = contents)), cache, auto_unbox = FALSE
)
assert(!is.null(focused_build_problem(before, before, fixture)), "Missing listing caches must require a full build.")
write_cache(post)
assert(is.null(focused_build_problem(before, before, fixture)), "Unchanged archives with a complete cache must allow a focused build.")
write_cache("another/index.qmd")
assert(!is.null(focused_build_problem(before, before, fixture)), "Stale listing membership must require a full build.")
write_cache(post)
unlink(file.path(fixture, "_site", "search.json"))
assert(!is.null(focused_build_problem(before, before, fixture)), "Incomplete site indexes must require a full build.")
writeLines("fixture", file.path(fixture, "_site", "search.json"))
writeLines(c("---", "listing:", "  contents: []", "---"), file.path(fixture, "index.qmd"))
after <- archive_fingerprints(fixture)
assert(!is.null(focused_build_problem(before, after, fixture)), "Changed published membership must require a full build.")
assert(!is.null(focused_build_problem(before, c(before, new = "hash"), fixture)), "New archives must require a full build.")
assert(!is.null(focused_build_problem(before, before[FALSE], fixture)), "Deleted archives must require a full build.")
dir.create(dirname(file.path(fixture, post)), recursive = TRUE)
writeLines("Fixture post.", file.path(fixture, post))
dir.create(file.path(fixture, "blog"))
writeLines(c("---", "listing:", "  contents:", paste0("    - ../", post), "---"),
  file.path(fixture, "blog/index.qmd"))
writeLines(c("---", "listing:", "  contents: []", "---"), file.path(fixture, "unrelated.qmd"))
assert(identical(post_listing_inputs(post, c("blog/index.qmd", "unrelated.qmd"), fixture), "blog/index.qmd"),
  "Dependent listings must resolve parent-relative paths and exclude unrelated listings.")
unlink(fixture, recursive = TRUE)
cat("Focused build safeguards passed.\n")
