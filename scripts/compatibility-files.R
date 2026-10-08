#!/usr/bin/env Rscript

root <- normalizePath(getwd(), mustWork = TRUE)
site <- file.path(root, "_site")
source(file.path(root, "scripts", "feeds.R"))

strip_post_sidebars <- function(path) {
  if (!file.exists(path)) return(invisible(FALSE))
  feed <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  feed <- strip_post_sidebar_html(feed)
  lines <- strsplit(feed, "\n", fixed = TRUE)[[1L]]
  lines <- sub("(<description><!\\[CDATA\\[)[ \t]+$", "\\1", lines)
  writeLines(lines, path, useBytes = TRUE)
  invisible(TRUE)
}

strip_post_sidebars(file.path(site, "index.xml"))
strip_post_sidebars(file.path(site, "feed-R", "index.xml"))

if (file.exists(file.path(site, "index.xml"))) {
  file.copy(file.path(site, "index.xml"), file.path(site, "feed.xml"), overwrite = TRUE)
}
if (file.exists(file.path(site, "feed-R", "index.xml"))) {
  r_feed <- file.path(site, "feed-R.xml")
  file.copy(file.path(site, "feed-R", "index.xml"), r_feed, overwrite = TRUE)
  lines <- readLines(r_feed, warn = FALSE, encoding = "UTF-8")
  lines <- sub(
    "https://fromthebottomoftheheap.net/feed-R/index.xml",
    "https://fromthebottomoftheheap.net/feed-R.xml",
    lines,
    fixed = TRUE
  )
  lines <- gsub(
    'href="(\\.\\./)+',
    'href="https://fromthebottomoftheheap.net/',
    lines,
    perl = TRUE
  )
  lines <- gsub(
    'src="(\\.\\./)+',
    'src="https://fromthebottomoftheheap.net/',
    lines,
    perl = TRUE
  )
  writeLines(lines, r_feed, useBytes = TRUE)
}

# Omit optional filesystem timestamps and sort URLs for deterministic builds.
sitemap <- file.path(site, "sitemap.xml")
if (file.exists(sitemap)) {
  lines <- readLines(sitemap, warn = FALSE, encoding = "UTF-8")
  writeLines(normalize_sitemap(lines), sitemap, useBytes = TRUE)
}

writeLines(
  "https://www.fromthebottomoftheheap.net/* https://fromthebottomoftheheap.net/:splat 301!",
  file.path(site, "_redirects"), useBytes = TRUE
)
