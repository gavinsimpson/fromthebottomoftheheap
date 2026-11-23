#!/usr/bin/env Rscript

options(warn = 2)
# renv checked the environment during this R session's startup; Quarto's R
# subprocesses can use it without repeating the same consistency check.
Sys.setenv(RENV_CONFIG_SYNCHRONIZED_CHECK = "false")
arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) > 1L) stop("Usage: Rscript scripts/render-site.R [path/to/post/index.qmd]")
source("scripts/posts.R")
source("scripts/build.R")
if (length(arguments)) {
  post <- sub("^\\./", "", arguments[[1L]])
  if (!post %in% discover_posts(include_drafts = TRUE)$qmd) {
    stop("The focused build expects a dated post's index.qmd path.")
  }
}

quarto <- unname(Sys.which("quarto"))
if (!nzchar(quarto)) stop("Quarto was not found on PATH.")

before <- if (length(arguments)) archive_fingerprints() else NULL
source("scripts/generate-archives.R", local = new.env())

if (length(arguments)) {
  after <- archive_fingerprints()
  reason <- focused_build_problem(before, after)
  if (!is.null(reason)) {
    stop(reason, " Run Rscript scripts/render-site.R for a full build.", call. = FALSE)
  }
  # Render dependent listings after the post so full-content feeds pick up
  # its freshly executed output, including on Quarto versions that miss
  # listing dependencies whose contents use ../ paths.
  listings <- post_listing_inputs(post, names(after))
  targets <- c(post, setdiff(listings, "index.qmd"))
  sitemap <- file.path("_site", "sitemap.xml")
  previous_sitemap <- readLines(sitemap, warn = FALSE)
  message("Rendering ", post, " and its dependent listings.")
  render_arguments <- c("render", shQuote(targets), "--no-clean")
} else {
  render_arguments <- "render"
}
status <- system2(quarto, render_arguments)
if (!identical(status, 0L)) stop("Quarto render failed")
if (length(arguments)) {
  source("scripts/feeds.R")
  writeLines(merge_sitemaps(previous_sitemap, readLines(sitemap, warn = FALSE)), sitemap)
}
source("scripts/compatibility-files.R", local = new.env())
message("Build complete. Validate once with Rscript scripts/check-site.R")
