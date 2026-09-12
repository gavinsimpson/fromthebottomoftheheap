#!/usr/bin/env Rscript

options(warn = 2)

root <- normalizePath(getwd(), mustWork = TRUE)
posts_dir <- if (dir.exists(file.path(root, "archive", "generated-markdown"))) {
  file.path(root, "archive", "generated-markdown")
} else {
  file.path(root, "_posts")
}
rmd_dir <- if (dir.exists(file.path(root, "archive", "rmd"))) {
  file.path(root, "archive", "rmd")
} else {
  file.path(root, "_posts")
}

if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("The yaml package is required to run the one-time content migration.")
}

read_document <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) < 3L || trimws(lines[[1L]]) != "---") {
    return(list(metadata = list(), body = lines))
  }
  end <- which(trimws(lines[-1L]) == "---")[[1L]] + 1L
  metadata <- yaml::yaml.load(paste(lines[2L:(end - 1L)], collapse = "\n"))
  list(metadata = metadata, body = lines[(end + 1L):length(lines)])
}

write_document <- function(path, metadata, body) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  front <- strsplit(yaml::as.yaml(metadata, indent.mapping.sequence = TRUE), "\n", fixed = TRUE)[[1L]]
  front <- sub(": no$", ": false", front)
  front <- sub(": yes$", ": true", front)
  writeLines(c("---", front, "---", "", body), path, useBytes = TRUE)
}

baseline_files <- system2(
  "git", c("ls-tree", "-r", "--name-only", "HEAD", "_site"),
  stdout = TRUE, stderr = TRUE
)
if (!length(baseline_files)) stop("Could not read the baseline _site tree from Git")
baseline_routes <- grep("(^_site/index\\.html$|/index\\.html$)", baseline_files, value = TRUE)
baseline_routes <- sub("^_site", "", baseline_routes)
baseline_routes <- sub("index\\.html$", "", baseline_routes)
baseline_routes[baseline_routes == "/"] <- "/"

post_url <- function(stem) {
  slug <- sub("^\\d{4}-\\d{2}-\\d{2}-", "", stem)
  matches <- grep(paste0("^/\\d{4}/\\d{2}/\\d{2}/", slugify(slug), "/$"), baseline_routes, value = TRUE)
  if (length(matches) == 1L) return(matches)
  sub("^(\\d{4})-(\\d{2})-(\\d{2})-(.+)$", "/\\1/\\2/\\3/\\4/", stem)
}

post_path <- function(url) file.path(root, sub("/$", "", sub("^/", "", url)), "index.qmd")

slugify <- function(x) {
  x <- iconv(x, to = "ASCII//TRANSLIT")
  x <- tolower(gsub("[^A-Za-z0-9]+", "-", x))
  gsub("(^-|-$)", "", x)
}

bibliography <- readLines(file.path(root, "_biblio", "blog-biblio.bib"), warn = FALSE)
bib_entries <- grep("^@[[:alnum:]_]+\\s*\\{[^,]+,", bibliography, value = TRUE)
citation_keys <- sub("^@[[:alnum:]_]+\\s*\\{([^,]+),.*$", "\\1", bib_entries)
all_markdown <- unlist(lapply(sort(list.files(posts_dir, pattern = "\\.md$", full.names = TRUE)), readLines, warn = FALSE), use.names = FALSE)
handle_matches <- gregexpr("(?<![[:alnum:]_])@[A-Za-z][A-Za-z0-9_:-]*", all_markdown, perl = TRUE)
handles <- unique(sub("^@", "", unlist(regmatches(all_markdown, handle_matches), use.names = FALSE)))
social_handles <- setdiff(handles, citation_keys)

escape_social_handles <- function(text) {
  for (handle in social_handles) {
    text <- gsub(
      paste0("(?<!\\\\)@", handle),
      paste0(intToUtf8(92L), intToUtf8(92L), "@", handle),
      text,
      perl = TRUE
    )
  }
  text
}

listing_description <- function(body) {
  lines <- body
  in_fence <- FALSE
  keep <- logical(length(lines))
  for (i in seq_along(lines)) {
    if (grepl("^`{3,}", lines[[i]])) {
      in_fence <- !in_fence
    } else if (!in_fence) {
      keep[[i]] <- TRUE
    }
  }
  lines <- lines[keep]
  blocks <- strsplit(paste(lines, collapse = "\n"), "\n[[:space:]]*\n", perl = TRUE)[[1L]]
  blocks <- trimws(blocks)
  blocks <- blocks[
    nzchar(blocks) &
      !grepl("^(#{1,6}[[:space:]]|<|!?\\[?!?\\[|[*_]?[Ii]mage(?:[[:space:]]|[*_:])|\\||:::|\\{%|\\{\\{)", blocks, perl = TRUE)
  ]
  text <- if (length(blocks)) blocks[[1L]] else ""
  text <- gsub("!\\[([^]]*)\\]\\([^)]*\\)", "", text, perl = TRUE)
  text <- gsub("\\[([^]]+)\\]\\([^)]*\\)", "\\1", text, perl = TRUE)
  text <- gsub("<[^>]+>", " ", text, perl = TRUE)
  text <- gsub("[`*_]", "", text)
  gsub("[[:space:]]+", " ", trimws(text))
}

post_margin <- function(category, tags) {
  out <- c("::: {.column-margin .post-taxonomy}")
  if (!is.null(category) && nzchar(as.character(category))) {
    out <- c(out, "#### Posted in", paste0("[", category, "](/category/", slugify(as.character(category)), "/){.badge .text-bg-warning}"), "")
  }
  tags <- unlist(tags)
  tags <- tags[nzchar(tags)]
  if (length(tags)) {
    out <- c(out, "#### Tagged", paste0("[", tags, "](/tag/", vapply(tags, slugify, character(1L)), "/){.badge .text-bg-dark}"))
  }
  c(
    out,
    ":::",
    "",
    "::: {.column-margin .post-links}",
    "{{< include ../../../../includes/social-blogroll.qmd >}}",
    ":::",
    ""
  )
}

replace_liquid <- function(body, excerpt = NULL) {
  text <- paste(body, collapse = "\n")
  text <- gsub("\\{\\{\\s*site\\.(url|baseurl)\\s*\\}\\}", "", text, perl = TRUE)
  text <- gsub("\\{\\{\\s*site_url\\s*\\}\\}", "", text, perl = TRUE)
  text <- gsub(
    "\\{%\\s*post_url\\s+(\\d{4})-(\\d{2})-(\\d{2})-([^ %}]+)\\s*%\\}",
    "/\\1/\\2/\\3/\\4/", text, perl = TRUE
  )
  if (!is.null(excerpt) && length(excerpt) == 1L) {
    text <- gsub("\\{\\{\\s*page\\.excerpt\\s*\\|\\s*m?a?r?k?downify\\s*\\}\\}", excerpt, text, perl = TRUE)
  }
  text <- gsub("\\{%\\s*highlight\\s+([^ %}]+)(?:\\s+linenos)?\\s*%\\}", "```\\1", text, perl = TRUE)
  text <- gsub("\\{%\\s*endhighlight\\s*%\\}", "```", text, perl = TRUE)
  text <- gsub('class="thumbnails pull-left ftboth-img-right"', 'class="list-unstyled float-start me-3 ftboth-img-right"', text, fixed = TRUE)
  text <- gsub('class="span([0-9]+)"', 'class="col-md-\\1"', text, perl = TRUE)
  text <- gsub('class="thumbnail"', 'class="border rounded p-1"', text, fixed = TRUE)
  if (exists("post_source_urls", inherits = TRUE) && exists("post_urls", inherits = TRUE)) {
    for (i in which(post_source_urls != post_urls)) {
      text <- gsub(post_source_urls[[i]], post_urls[[i]], text, fixed = TRUE)
    }
  }
  text <- escape_social_handles(text)
  strsplit(text, "\n", fixed = TRUE)[[1L]]
}

extract_r_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^`{3,}\\{r(?:[ ,][^}]*)?\\}\\s*$", lines, perl = TRUE)
  chunks <- vector("list", length(starts))
  for (i in seq_along(starts)) {
    start <- starts[[i]]
    opening <- regmatches(lines[[start]], regexpr("^`+", lines[[start]]))
    fence_pattern <- paste0("^`{", nchar(opening), ",}\\s*$")
    finish_candidates <- which(seq_along(lines) > start & grepl(fence_pattern, lines, perl = TRUE))
    if (!length(finish_candidates)) stop("Unclosed R chunk in ", path, " at line ", start)
    finish <- finish_candidates[[1L]]
    header <- sub("^```\\{r\\s*", "", lines[[start]])
    header <- sub("\\}\\s*$", "", header)
    label_bits <- strsplit(header, ",", fixed = TRUE)[[1L]]
    label <- if (length(label_bits)) trimws(label_bits[[1L]]) else ""
    if (!nzchar(label)) label <- paste0("historical-r-chunk-", i)
    label <- gsub("[^A-Za-z0-9_-]+", "-", label)
    code <- if (finish > start + 1L) lines[(start + 1L):(finish - 1L)] else character()
    chunks[[i]] <- c(
      paste0("```{r ", label, "}"),
      "#| eval: false",
      "#| echo: false",
      "#| output: false",
      "#| include: false",
      code,
      "```",
      ""
    )
  }
  chunks
}

md_files <- sort(list.files(posts_dir, pattern = "\\.md$", full.names = TRUE))
rmd_files <- sort(list.files(rmd_dir, pattern = "\\.Rmd$", full.names = TRUE))

if (length(md_files) != 103L || length(rmd_files) != 37L) {
  stop("Expected 103 Markdown posts and 37 Rmd archives; found ", length(md_files), " and ", length(rmd_files), ".")
}

baseline_dir <- file.path(root, "migration")
dir.create(baseline_dir, recursive = TRUE, showWarnings = FALSE)
rmd_hashes <- tools::md5sum(rmd_files)
write.table(
  data.frame(path = sub(paste0("^", root, "/"), "", names(rmd_hashes)), md5 = unname(rmd_hashes)),
  file.path(baseline_dir, "rmd-md5.tsv"), sep = "\t", row.names = FALSE, quote = FALSE
)
writeLines(sort(unique(baseline_routes)), file.path(baseline_dir, "route-manifest.txt"), useBytes = TRUE)

manifest <- vector("list", length(md_files))
post_stems <- sub("\\.md$", "", basename(md_files))
post_source_urls <- sub("^(\\d{4})-(\\d{2})-(\\d{2})-(.+)$", "/\\1/\\2/\\3/\\4/", post_stems)
post_urls <- vapply(post_stems, post_url, character(1L))
post_titles <- vapply(md_files, function(path) {
  value <- read_document(path)$metadata$title
  if (is.null(value)) sub("^\\d{4}-\\d{2}-\\d{2}-", "", basename(path)) else as.character(value)
}, character(1L))

post_navigation <- function(i) {
  older <- if (i > 1L) paste0("[← Older: ", post_titles[[i - 1L]], "](", post_urls[[i - 1L]], ")") else ""
  newer <- if (i < length(md_files)) paste0("[Newer: ", post_titles[[i + 1L]], " →](", post_urls[[i + 1L]], ")") else ""
  c(
    "", "::: {.post-navigation .d-flex .justify-content-between .gap-3}",
    paste0("<span>", older, "</span>"), paste0("<span class=\"text-end\">", newer, "</span>"),
    ":::"
  )
}

for (i in seq_along(md_files)) {
  md <- md_files[[i]]
  stem <- sub("\\.md$", "", basename(md))
  parsed <- read_document(md)
  meta <- parsed$metadata
  original_meta <- meta
  if (!is.null(meta$title)) meta$title <- as.character(meta$title)
  if (!is.null(meta$subtitle) && identical(meta$subtitle, FALSE)) meta$subtitle <- NULL
  if (!is.null(meta$subtitle)) meta$subtitle <- as.character(meta$subtitle)
  if (!is.null(meta$excerpt)) meta$excerpt <- escape_social_handles(as.character(meta$excerpt))
  meta$description <- escape_social_handles(listing_description(parsed$body))
  if (!is.null(meta$category)) {
    meta$category <- as.character(meta$category)
    if (tolower(meta$category) == "science") meta$category <- "Science"
  }
  if (is.null(meta$image) && !is.null(meta$twitterimg) && nzchar(as.character(meta$twitterimg))) {
    meta$image <- paste0("/assets/img/posts/", as.character(meta$twitterimg))
  }
  meta$twitterimg <- NULL
  if (!is.null(meta$tags)) meta$tags <- as.list(as.character(unlist(meta$tags)))

  for (field in c("layout", "status", "type", "active", "published")) meta[[field]] <- NULL
  if (is.null(meta$date)) meta$date <- paste0(sub("^(\\d{4})-(\\d{2})-(\\d{2}).*$", "\\1-\\2-\\3", stem), " 12:00:00")
  meta$author <- "Gavin Simpson"
  if (!is.null(meta$category)) meta$categories <- list(as.character(meta$category))
  meta$comments <- list(giscus = list(
    repo = "gavinsimpson/fromthebottomoftheheap-comments",
    category = "Blog comments",
    mapping = "pathname",
    `reactions-enabled` = TRUE,
    `input-position` = "top",
    theme = "preferred_color_scheme",
    language = "en"
  ))

  body <- c(
    post_margin(meta$category, meta$tags),
    replace_liquid(parsed$body, original_meta$excerpt),
    post_navigation(i)
  )
  rmd <- file.path(rmd_dir, paste0(stem, ".Rmd"))
  chunk_count <- 0L
  if (file.exists(rmd)) {
    chunks <- extract_r_chunks(rmd)
    chunk_count <- length(chunks)
    body <- c(
      body,
      "",
      "<!--",
      "Historical R chunks follow. They are retained for archival reference and are",
      "individually disabled so that Quarto can never execute or display them.",
      "-->",
      "",
      "```{r historical-execution-sentinel}",
      "#| eval: false",
      "#| echo: false",
      "#| output: false",
      "#| include: false",
      'stop("A historical post attempted to execute R code")',
      "```",
      "",
      unlist(chunks, use.names = FALSE)
    )
  }

  url <- post_url(stem)
  out <- post_path(url)
  write_document(out, meta, body)
  manifest[[i]] <- data.frame(
    source = sub(paste0("^", root, "/"), "", md),
    qmd = sub(paste0("^", root, "/"), "", out),
    url = url,
    title = if (is.null(original_meta$title)) "" else as.character(original_meta$title),
    subtitle = if (is.null(original_meta$subtitle) || identical(original_meta$subtitle, FALSE)) "" else as.character(original_meta$subtitle),
    date = if (is.null(original_meta$date)) "" else as.character(original_meta$date),
    excerpt = if (is.null(original_meta$excerpt)) "" else paste(as.character(original_meta$excerpt), collapse = " "),
    image = if (is.null(original_meta$image)) "" else as.character(original_meta$image),
    publication_state = paste(
      unlist(original_meta[intersect(c("status", "published"), names(original_meta))]),
      collapse = ";"
    ),
    permalink = url,
    category = if (is.null(meta$category)) "" else as.character(meta$category),
    tags = if (is.null(original_meta$tags)) "" else paste(unlist(original_meta$tags), collapse = "|"),
    archived_rmd = file.exists(rmd),
    hidden_chunks = chunk_count,
    stringsAsFactors = FALSE
  )
}

manifest <- do.call(rbind, manifest)
write.csv(manifest, file.path(baseline_dir, "post-manifest.csv"), row.names = FALSE, quote = TRUE)

message("Created ", nrow(manifest), " historical QMD posts; ", sum(manifest$archived_rmd), " retain hidden R chunks.")
