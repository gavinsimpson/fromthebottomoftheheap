#!/usr/bin/env Rscript

root <- normalizePath(getwd(), mustWork = TRUE)
site <- file.path(root, "_site")

strip_post_sidebars <- function(path) {
  if (!file.exists(path)) return(invisible(FALSE))
  feed <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  feed <- gsub(
    '(?s)<div class="post-links">.*?</div></div>\n<p>',
    "</div><p>",
    feed,
    perl = TRUE
  )
  writeLines(strsplit(feed, "\n", fixed = TRUE)[[1L]], path, useBytes = TRUE)
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
