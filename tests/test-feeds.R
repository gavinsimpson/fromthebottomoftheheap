#!/usr/bin/env Rscript

source("scripts/feeds.R")
assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}
item <- function(title, whitespace) paste0(
  "<item><title>", title, "</title><description><![CDATA[",
  '<div class="column-margin"><div class="post-links"><section>Social</section></div></div>',
  whitespace, "<p>", title, " body.</p>]]></description></item>"
)
items <- c(item("New post", ""), item("Older post", "\n"), item("Another post", "\n\n"))
cleaned <- strip_post_sidebar_html(paste(items, collapse = "\n"))
assert(!grepl("post-links|Social", cleaned), "Feed cleanup must remove sidebars with or without whitespace before the body.")
assert(all(vapply(c("New post", "Older post", "Another post"), function(title) {
  grepl(paste0("<p>", title, " body.</p>"), cleaned, fixed = TRUE)
}, logical(1L))), "Feed cleanup must preserve every post body.")
assert(lengths(regmatches(cleaned, gregexpr("<item>", cleaned, fixed = TRUE))) == length(items),
  "Feed cleanup must preserve every RSS item.")
incomplete <- '<item><description><![CDATA[<div class="post-links">Social</div></div>]]></description></item>'
adjacent <- strip_post_sidebar_html(paste0(incomplete, items[[2L]]))
assert(startsWith(adjacent, incomplete) && grepl("<p>Older post body.</p>", adjacent, fixed = TRUE),
  "An unmatched sidebar must never consume a neighbouring item's content.")
sitemap <- function(urls) c(
  '<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
  unlist(lapply(urls, function(url) c("  <url>", paste0("    <loc>", url, "</loc>"),
    "    <lastmod>2026-10-08</lastmod>", "  </url>"))), "</urlset>"
)
urls <- c("https://example.test/z/", "https://example.test/a/")
normalized <- normalize_sitemap(sitemap(urls))
assert(identical(normalized, normalize_sitemap(sitemap(rev(urls)))) &&
    identical(normalized, normalize_sitemap(normalized)),
  "Sitemap normalization must be independent of render order and idempotent.")
assert(!any(grepl("lastmod", normalized)) && all(vapply(urls, function(url) {
  any(grepl(paste0("<loc>", url, "</loc>"), normalized, fixed = TRUE))
}, logical(1L))), "Sitemap normalization must preserve every URL while removing filesystem timestamps.")
cat("Feed cleanup tests passed.\n")
