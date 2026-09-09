#!/usr/bin/env Rscript

root <- normalizePath(getwd(), mustWork = TRUE)
site <- file.path(root, "_site")

if (file.exists(file.path(site, "index.xml"))) {
  file.copy(file.path(site, "index.xml"), file.path(site, "feed.xml"), overwrite = TRUE)
}
if (file.exists(file.path(site, "feed-R", "index.xml"))) {
  file.copy(file.path(site, "feed-R", "index.xml"), file.path(site, "feed-R.xml"), overwrite = TRUE)
}

# Quarto derives sitemap last-modified values from filesystem mtimes, which
# makes an otherwise identical local render change this committed artifact.
# lastmod is optional in the sitemap protocol, so omit it deterministically.
sitemap <- file.path(site, "sitemap.xml")
if (file.exists(sitemap)) {
  lines <- readLines(sitemap, warn = FALSE, encoding = "UTF-8")
  writeLines(lines[!grepl("<lastmod>", lines, fixed = TRUE)], sitemap, useBytes = TRUE)
}

writeLines(
  "https://www.fromthebottomoftheheap.net/* https://fromthebottomoftheheap.net/:splat 301!",
  file.path(site, "_redirects"), useBytes = TRUE
)
