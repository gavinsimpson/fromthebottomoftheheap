#!/usr/bin/env Rscript

# Optional tooling integration test: renders only a tiny temporary site.
# Kept separate from check-site.R, which must never invoke Quarto.
check_render_integration <- function() {
  project <- normalizePath(getwd())
  fixture <- tempfile("blog-build-integration-", tmpdir = "/private/tmp")
  dir.create(fixture)
  message("Testing renders in ", fixture)
  on.exit(setwd(project), add = TRUE)
  on.exit(unlink(fixture, recursive = TRUE), add = TRUE)
  for (directory in c("scripts", "includes", "blog", "feed-R")) dir.create(file.path(fixture, directory))
  scripts <- c("render-site.R", "build.R", "posts.R", "generate-archives.R", "compatibility-files.R", "feeds.R")
  invisible(file.copy(file.path(project, "scripts", scripts), file.path(fixture, "scripts")))
  writeLines("Social fixture.", file.path(fixture, "includes/social-blogroll.qmd"))
  writeLines("<!-- pagination fixture -->", file.path(fixture, "includes/blog-pagination.html"))
  writeLines(c("project:", "  type: website", "  output-dir: _site", "  render:",
    "    - index.qmd", "    - blog/**/*.qmd", "    - feed-R/index.qmd", "    - '20*/**/index.qmd'",
    "    - category/**/*.qmd", "    - tag/**/*.qmd", "website:", "  title: Fixture",
    "  site-url: https://fromthebottomoftheheap.net", "format: html"), file.path(fixture, "_quarto.yml"))
  post <- "2026/01/01/example/index.qmd"
  unrelated <- "2026/01/02/unrelated/index.qmd"
  draft <- "2026/01/03/draft/index.qmd"
  write_post <- function(path, fields, body) {
    target <- file.path(fixture, path)
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    writeLines(c("---", fields, "---", "", body), target)
  }
  fields <- c("title: Example", "date: 2026-01-01", "categories: [R]", "tags: [example]", "freeze: auto")
  write_post(post, fields, c("Original body.", "", "```{r}", "1 + 1", "```"))
  write_post(unrelated, c("title: Unrelated", "date: 2026-01-02", "categories: [Science, R]", "tags: [other]"), "Untouched body.")
  write_post(draft, c("title: Draft", "date: 2026-01-03", "draft: true"), "Secret draft body.")
  setwd(fixture)
  run <- function(arguments = character()) {
    status <- system2("Rscript", c("scripts/render-site.R", shQuote(arguments)), stdout = "render.log", stderr = "render.log")
    if (status != 0L) stop(paste(readLines("render.log"), collapse = "\n"))
  }
  run()
  source(file.path(project, "scripts/posts.R"))
  source(file.path(project, "scripts/build.R"))
  a <- archive_fingerprints()
  stopifnot(is.null(focused_build_problem(a, a)))
  html <- function(path) file.path("_site", sub("\\.qmd$", ".html", path))
  unchanged_paths <- html(c(unrelated, "category/science/index.qmd", "tag/other/index.qmd"))
  before <- file.info(unchanged_paths)$mtime
  write_post(post, fields, c("Updated body marker.", "", "```{r}", "1 + 2", "```"))
  run(post)
  stopifnot(identical(before, file.info(unchanged_paths)$mtime))
  for (path in c(html(post), "_site/feed.xml", "_site/feed-R.xml")) {
    content <- paste(readLines(path, warn = FALSE), collapse = "\n")
    stopifnot(grepl("Updated body marker", content, fixed = TRUE), grepl("[1] 3", content, fixed = TRUE))
  }
  search <- paste(readLines("_site/search.json", warn = FALSE), collapse = "\n")
  sitemap <- paste(readLines("_site/sitemap.xml"), collapse = "\n")
  stopifnot(grepl("unrelated", search), grepl("unrelated", sitemap), grepl("Updated body marker", search))
  stopifnot(!grepl("Secret draft body", search))
  write_post(post, c(fields, "draft: true"), "Now a draft.")
  status <- system2("Rscript", c("scripts/render-site.R", shQuote(post)), stdout = "guard.log", stderr = "guard.log")
  stopifnot(status != 0L, any(grepl("published inventory", readLines("guard.log"))))
  cat("Render integration passed: R output, feeds, search, sitemap, unrelated pages, and draft safeguards.\n")
}

check_render_integration()
