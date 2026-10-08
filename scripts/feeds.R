# Remove the generated Social sidebar without crossing an RSS description's
# CDATA boundary. Quarto may put the first body paragraph immediately after
# the margin container or separate it with whitespace.
strip_post_sidebar_html <- function(text) {
  gsub(
    '(?s)<div class="post-links">(?:(?!\\]\\]>).)*?</div>\\s*</div>\\s*<p>',
    "</div><p>",
    text,
    perl = TRUE
  )
}

# Quarto's sitemap ordering depends on render order and filesystem mtimes.
# Neither ordering nor lastmod should cause otherwise identical builds to differ.
normalize_sitemap <- function(lines) {
  text <- paste(lines[!grepl("<lastmod>", lines, fixed = TRUE)], collapse = "\n")
  blocks <- regmatches(text, gregexpr("(?s)<url>.*?</url>", text, perl = TRUE))[[1L]]
  if (!length(blocks)) return(strsplit(text, "\n", fixed = TRUE)[[1L]])
  urls <- sub("(?s).*<loc>(.*?)</loc>.*", "\\1", blocks, perl = TRUE)
  prefix <- sub("(?s)<url>.*$", "", text, perl = TRUE)
  suffix <- sub("(?s)^.*</url>", "", text, perl = TRUE)
  result <- paste0(prefix, paste(blocks[order(urls, method = "radix")], collapse = "\n  "), suffix)
  strsplit(result, "\n", fixed = TRUE)[[1L]]
}
