#!/usr/bin/env Rscript

options(warn = 2)
root <- normalizePath(getwd(), mustWork = TRUE)
manifest_path <- file.path(root, "migration", "post-manifest.csv")
if (!file.exists(manifest_path)) stop("Missing migration/post-manifest.csv")
posts <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)

write_post_listing <- function(path, prefix, home = FALSE) {
  contents <- paste0("    - ", prefix, posts$qmd)
  lines <- c(
    "---",
    if (home) "title: From the bottom of the heap" else "title: Blog posts",
    if (home) "subtitle: the musings of a geographer" else NULL,
    "listing:",
    "  contents:",
    contents,
    "  sort: date desc",
    paste0("  type: ", if (home) "default" else "table"),
    if (home) "  max-items: 10" else NULL,
    if (!home) "  fields: [date, title, subtitle, category]" else NULL,
    "  categories: true",
    if (home) c(
      "  feed:",
      "    type: full",
      "    items: 50",
      "    title: From the bottom of the heap"
    ) else NULL,
    "comments: false",
    "page-layout: full",
    "---",
    if (home) c("", "::: {.more-posts}", "[More posts →](/blog/)", ":::") else NULL
  )
  writeLines(lines, file.path(root, path), useBytes = TRUE)
}

write_post_listing("index.qmd", "", home = TRUE)
write_post_listing("blog/index.qmd", "../", home = FALSE)

slugify <- function(x) {
  x <- iconv(x, to = "ASCII//TRANSLIT")
  x <- tolower(gsub("[^A-Za-z0-9]+", "-", x))
  gsub("(^-|-$)", "", x)
}

yaml_quote <- function(x) paste0('"', gsub('"', '\\"', x, fixed = TRUE), '"')

write_archive <- function(kind, values, selected) {
  values <- sort(unique(values))
  slug <- slugify(values[[1L]])
  path <- file.path(root, kind, slug, "index.qmd")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  rel <- vapply(selected$qmd, function(x) paste0("../../", x), character(1L))
  lines <- c(
    "---",
    paste0("title: ", yaml_quote(paste0(tools::toTitleCase(kind), ": ", paste(values, collapse = " / ")))),
    "listing:",
    "  type: table",
    "  sort: date desc",
    "  fields: [date, title]",
    "  contents:",
    paste0("    - ", rel),
    "page-layout: full",
    "comments: false",
    "---"
  )
  writeLines(lines, path, useBytes = TRUE)
}

categories <- sort(unique(posts$category[!is.na(posts$category) & nzchar(posts$category)]))
category_slugs <- vapply(categories, slugify, character(1L))
for (slug in sort(unique(category_slugs))) {
  values <- categories[category_slugs == slug]
  write_archive("category", values, posts[posts$category %in% values, , drop = FALSE])
}

tag_rows <- do.call(rbind, lapply(seq_len(nrow(posts)), function(i) {
  tags <- strsplit(posts$tags[[i]], "|", fixed = TRUE)[[1L]]
  tags <- tags[!is.na(tags) & nzchar(tags)]
  if (!length(tags)) return(NULL)
  data.frame(tag = tags, row = i, stringsAsFactors = FALSE)
}))
if (!is.null(tag_rows)) {
  tags <- sort(unique(tag_rows$tag))
  tag_slugs <- vapply(tags, slugify, character(1L))
  for (slug in sort(unique(tag_slugs))) {
    values <- tags[tag_slugs == slug]
    write_archive("tag", values, posts[unique(tag_rows$row[tag_rows$tag %in% values]), , drop = FALSE])
  }
}

r_posts <- posts[tolower(posts$category) == "r", , drop = FALSE]
r_contents <- paste0("    - ../", r_posts$qmd)
writeLines(c(
  "---",
  "title: R posts",
  "listing:",
  "  contents:",
  r_contents,
  "  sort: date desc",
  "  type: table",
  "  feed:",
  "    type: full",
  "    items: 50",
  "    title: From the bottom of the heap — R posts",
  "comments: false",
  "page-layout: full",
  "---"
), file.path(root, "feed-R", "index.qmd"), useBytes = TRUE)

message(
  "Generated ", length(unique(category_slugs)), " category archives and ",
  if (is.null(tag_rows)) 0L else length(unique(tag_slugs)), " tag archives."
)
