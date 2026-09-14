#!/usr/bin/env Rscript

options(warn = 2)
root <- normalizePath(getwd(), mustWork = TRUE)
manifest_path <- file.path(root, "migration", "post-manifest.csv")
if (!file.exists(manifest_path)) stop("Missing migration/post-manifest.csv")
posts <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)

year_matches <- regexec("^([0-9]{4})/", posts$qmd)
post_years <- regmatches(posts$qmd, year_matches)
if (any(lengths(post_years) != 2L)) {
  stop("Every post QMD path must begin with a four-digit year")
}
posts$year <- as.integer(vapply(post_years, `[[`, character(1L), 2L))
years <- sort(unique(posts$year), decreasing = TRUE)

year_selector <- function(selected_year = NULL) {
  item <- function(label, href, active = FALSE) {
    paste0(
      '<li><a class="dropdown-item', if (active) " active" else "", '"',
      if (active) ' aria-current="page"' else "", ' href="', href, '">',
      label, "</a></li>"
    )
  }
  selected_label <- if (is.null(selected_year)) "All years" else as.character(selected_year)
  c(
    '<nav class="blog-year-selector dropdown" aria-label="Blog archive by year">',
    paste0(
      '<button class="btn btn-outline-secondary dropdown-toggle" type="button" ',
      'data-bs-toggle="dropdown" aria-expanded="false">', selected_label, "</button>"
    ),
    '<ul class="dropdown-menu dropdown-menu-end">',
    item("All years", "/blog/", is.null(selected_year)),
    '<li><hr class="dropdown-divider"></li>',
    vapply(years, function(year) {
      item(as.character(year), paste0("/blog/", year, "/"), identical(selected_year, year))
    }, character(1L)),
    "</ul>",
    "</nav>"
  )
}

blog_header <- function(selected_year = NULL) year_selector(selected_year)

blog_layout <- function(include_path, header = NULL, more_posts = FALSE) {
  c(
    header,
    if (!is.null(header)) "" else NULL,
    "::::: {.home-layout}",
    ":::: {.home-posts}",
    "::: {#posts}",
    ":::",
    if (more_posts) c(
      "",
      "::: {.more-posts}",
      "[More posts →](/blog/)",
      ":::"
    ) else NULL,
    "::::",
    "",
    ":::: {.home-sidebar}",
    paste0("{{< include ", include_path, " >}}"),
    "::::",
    ":::::"
  )
}

write_post_listing <- function(path, prefix, home = FALSE) {
  contents <- paste0("    - ", prefix, posts$qmd)
  include_path <- paste0(prefix, "includes/social-blogroll.qmd")
  lines <- c(
    "---",
    if (home) "title: From the bottom of the heap" else NULL,
    if (!home) "title: Blog posts" else NULL,
    if (home) "subtitle: the musings of a geographer" else NULL,
    "listing:",
    "  id: posts",
    "  contents:",
    contents,
    "  sort: date desc",
    "  type: default",
    if (home) "  max-items: 10" else NULL,
    if (!home) "  page-size: 10" else NULL,
    "  categories: false",
    if (home) c(
      "  feed:",
      "    type: full",
      "    items: 50",
      "    title: From the bottom of the heap"
    ) else NULL,
    "comments: false",
    "page-layout: full",
    paste0("body-classes: ", if (home) "home-page" else "blog-page"),
    if (!home) c(
      "format:",
      "  html:",
      "    include-after-body: ../includes/blog-pagination.html"
    ) else NULL,
    "---",
    "",
    blog_layout(
      include_path,
      header = if (home) NULL else blog_header(),
      more_posts = home
    )
  )
  writeLines(lines, file.path(root, path), useBytes = TRUE)
}

write_post_listing("index.qmd", "", home = TRUE)
write_post_listing("blog/index.qmd", "../", home = FALSE)

write_year_listing <- function(year) {
  selected <- posts[posts$year == year, , drop = FALSE]
  path <- file.path(root, "blog", as.character(year), "index.qmd")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  lines <- c(
    "---",
    paste0('title: "Blog posts: ', year, '"'),
    "listing:",
    "  id: posts",
    "  contents:",
    paste0("    - ../../", selected$qmd),
    "  sort: date desc",
    "  type: default",
    paste0("  page-size: ", nrow(selected)),
    "  categories: false",
    "comments: false",
    "page-layout: full",
    "body-classes: blog-page",
    "---",
    "",
    blog_layout(
      "../../includes/social-blogroll.qmd",
      header = blog_header(year)
    )
  )
  writeLines(lines, path, useBytes = TRUE)
}

for (year in years) write_year_listing(year)

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

is_r_post <- function(path) {
  lines <- readLines(file.path(root, path), warn = FALSE, encoding = "UTF-8")
  yaml_end <- which(trimws(lines[-1L]) == "---")[[1L]] + 1L
  metadata <- yaml::yaml.load(paste(lines[2L:(yaml_end - 1L)], collapse = "\n"))
  categories <- c(
    as.character(unlist(metadata$category, use.names = FALSE)),
    as.character(unlist(metadata$categories, use.names = FALSE))
  )
  any(tolower(trimws(categories)) == "r")
}

dated_qmd <- list.files(root, pattern = "^index\\.qmd$", recursive = TRUE, full.names = FALSE)
dated_qmd <- dated_qmd[grepl("^20[0-9]{2}/[0-9]{2}/[0-9]{2}/[^/]+/index\\.qmd$", dated_qmd)]
r_qmd <- dated_qmd[vapply(dated_qmd, is_r_post, logical(1L))]
if (!length(r_qmd)) stop("No posts have R in their category or categories metadata")

r_contents <- paste0("    - ../", r_qmd)
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
  if (is.null(tag_rows)) 0L else length(unique(tag_slugs)), " tag archives, and ",
  length(years), " year archives; the full-content R feed contains ",
  length(r_qmd), " eligible posts."
)
