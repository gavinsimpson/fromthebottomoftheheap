#!/usr/bin/env Rscript

options(warn = 2)
root <- normalizePath(getwd(), mustWork = TRUE)

manifest <- read.csv(file.path(root, "migration", "post-manifest.csv"), stringsAsFactors = FALSE)
if (nrow(manifest) != 104L) stop("Expected 104 historical posts, found ", nrow(manifest))
if (sum(manifest$archived_rmd) != 37L) stop("Expected 37 archived Rmd posts")
if (anyDuplicated(manifest$qmd) || anyDuplicated(manifest$url)) stop("Historical QMD paths and URLs must be unique")
dated_qmd <- list.files(root, pattern = "^index\\.qmd$", recursive = TRUE, full.names = TRUE)
dated_qmd <- dated_qmd[grepl("/20[0-9]{2}/[0-9]{2}/[0-9]{2}/[^/]+/index\\.qmd$", dated_qmd)]
if (length(dated_qmd) != 104L) stop("Expected exactly 104 canonical dated QMD pages")

hashes <- read.delim(file.path(root, "migration", "rmd-md5.tsv"), stringsAsFactors = FALSE)
current <- tools::md5sum(file.path(root, hashes$path))
bad <- hashes$path[unname(current) != hashes$md5]
if (length(bad)) stop("Archived Rmd files changed: ", paste(bad, collapse = ", "))

quarto <- readLines(file.path(root, "_quarto.yml"), warn = FALSE)
if (any(grepl(".Rmd", quarto, fixed = TRUE))) stop("_quarto.yml must not name any Rmd render input")

legacy_jekyll <- c(".htaccess", "_config.yml", "_includes", "_layouts", "_plugins", "_posts")
remaining_jekyll <- legacy_jekyll[file.exists(file.path(root, legacy_jekyll))]
if (length(remaining_jekyll)) stop("Superseded Jekyll infrastructure remains: ", paste(remaining_jekyll, collapse = ", "))

legacy_assets <- c(
  "assets/css/bootstrap.css", "assets/css/bootstrap.min.css", "assets/css/ftboth.css",
  "assets/css/pyg_monokai.css", "assets/js/bootstrap.js", "assets/js/bootstrap.min.js",
  "assets/js/jquery.min.js"
)
remaining_assets <- legacy_assets[
  file.exists(file.path(root, legacy_assets)) | file.exists(file.path(root, "_site", legacy_assets))
]
if (length(remaining_assets)) stop("Superseded root Bootstrap assets remain: ", paste(remaining_assets, collapse = ", "))

read_chunks <- function(path, generated = FALSE) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^`{3,}\\{r(?:[ ,][^}]*)?\\}\\s*$", lines, perl = TRUE)
  chunks <- vector("list", length(starts))
  for (i in seq_along(starts)) {
    start <- starts[[i]]
    opening <- regmatches(lines[[start]], regexpr("^`+", lines[[start]]))
    finish <- which(seq_along(lines) > start & grepl(paste0("^`{", nchar(opening), ",}\\s*$"), lines, perl = TRUE))[[1L]]
    header <- sub("^`{3,}\\{r\\s*", "", lines[[start]], perl = TRUE)
    header <- sub("\\}\\s*$", "", header)
    fields <- strsplit(header, ",", fixed = TRUE)[[1L]]
    label <- if (length(fields)) trimws(fields[[1L]]) else ""
    if (!nzchar(label)) label <- paste0("historical-r-chunk-", i)
    label <- gsub("[^A-Za-z0-9_-]+", "-", label)
    first_code <- start + if (generated) 5L else 1L
    code <- if (finish > first_code) lines[first_code:(finish - 1L)] else character()
    chunks[[i]] <- list(label = label, code = code)
  }
  chunks
}

for (path in manifest$qmd[manifest$archived_rmd]) {
  lines <- readLines(file.path(root, path), warn = FALSE)
  starts <- grep("^```\\{r(?:[ ,][^}]*)?\\}\\s*$", lines, perl = TRUE)
  for (start in starts) {
    options <- lines[seq.int(start + 1L, min(start + 6L, length(lines)))]
    required <- c("#| eval: false", "#| echo: false", "#| output: false", "#| include: false")
    if (!all(required %in% options)) stop("Unsafe historical chunk in ", path, " at line ", start)
  }
  if (!any(grepl("^stop\\(\"A historical post attempted to execute R code\"\\)$", lines))) {
    stop("Missing historical execution sentinel in ", path)
  }
  row <- which(manifest$qmd == path)
  source_stem <- sub("\\.md$", "", basename(manifest$source[[row]]))
  source_chunks <- read_chunks(file.path(root, "archive", "rmd", paste0(source_stem, ".Rmd")))
  generated_chunks <- read_chunks(file.path(root, path), generated = TRUE)
  generated_chunks <- generated_chunks[vapply(generated_chunks, function(chunk) chunk$label != "historical-execution-sentinel", logical(1L))]
  if (!identical(source_chunks, generated_chunks)) stop("Historical chunk labels or bodies differ in ", path)
}

markdown_only <- manifest$qmd[!manifest$archived_rmd]
unexpected_engines <- markdown_only[vapply(markdown_only, function(path) {
  any(grepl("^`{3,}\\{(?:r|python|julia|ojs)(?:[ ,}])", readLines(file.path(root, path), warn = FALSE), perl = TRUE))
}, logical(1L))]
if (length(unexpected_engines)) stop("Executable chunks in Markdown-only archives: ", paste(unexpected_engines, collapse = ", "))

missing <- character()
for (url in manifest$url) {
  target <- file.path(root, "_site", sub("^/", "", url), "index.html")
  if (!file.exists(target)) missing <- c(missing, url)
}
if (length(missing)) stop("Missing rendered post routes: ", paste(missing, collapse = ", "))

baseline <- readLines(file.path(root, "migration", "route-manifest.txt"), warn = FALSE)
baseline_target <- function(route) {
  if (route == "/") file.path(root, "_site", "index.html") else file.path(root, "_site", sub("^/", "", route), "index.html")
}
missing_baseline <- baseline[!vapply(baseline, function(route) file.exists(baseline_target(route)), logical(1L))]
if (length(missing_baseline)) stop("Missing baseline routes: ", paste(missing_baseline, collapse = ", "))

home <- readLines(file.path(root, "_site", "index.html"), warn = FALSE)
blog <- readLines(file.path(root, "_site", "blog", "index.html"), warn = FALSE)
if (sum(grepl('class="quarto-post ', home, fixed = TRUE)) != 10L) stop("Home page must list exactly ten posts")
if (sum(grepl('data-index="', blog, fixed = TRUE)) != 104L) stop("Blog archive must list exactly 104 posts")
if (any(grepl("publications/365papers", home, fixed = TRUE))) stop("Home listing contains non-post content")

post_html <- file.path(root, "_site", sub("^/", "", manifest$url), "index.html")
rendered <- unlist(lapply(post_html, function(path) readLines(path, warn = FALSE)), use.names = FALSE)
if (any(grepl("assets/css/bootstrap.css|assets/js/bootstrap.js|class=.[^\"]*span[0-9]+", rendered))) {
  stop("Obsolete Bootstrap 2 assets or grid classes remain in rendered posts")
}
if (any(grepl("\\{%|\\{\\{", rendered))) stop("Unresolved Liquid syntax remains in rendered posts")
if (any(grepl("A historical post attempted to execute R code", rendered, fixed = TRUE))) {
  stop("The historical execution sentinel leaked into rendered output")
}
if (!all(vapply(post_html, function(path) any(grepl("giscus.app/client.js", readLines(path, warn = FALSE), fixed = TRUE)), logical(1L)))) {
  stop("Giscus is not enabled on every historical post")
}
giscus_ids <- c(
  'script.dataset.repoId = "R_kgDOUUVJuA";',
  'script.dataset.categoryId = "DIC_kwDOUUVJuM4DFRne";'
)
if (!all(vapply(post_html, function(path) {
  lines <- readLines(path, warn = FALSE)
  all(vapply(giscus_ids, function(value) any(grepl(value, lines, fixed = TRUE)), logical(1L)))
}, logical(1L)))) {
  stop("Giscus repository or category IDs are missing from a historical post")
}

netlify <- paste(readLines(file.path(root, "netlify.toml"), warn = FALSE), collapse = "\n")
if (!grepl('from = "/2011/10/21/228/"', netlify, fixed = TRUE) ||
    !grepl('to = "/2011/10/21/generating-sets-of-permutations/"', netlify, fixed = TRUE)) {
  stop("Missing Netlify redirect for the recovered WordPress post")
}

bootstrap_js <- list.files(file.path(root, "_site", "site_libs", "bootstrap"), pattern = "bootstrap.*\\.js$", full.names = TRUE)
if (!length(bootstrap_js) || !any(grepl("Bootstrap v5.3.1", unlist(lapply(bootstrap_js, readLines, warn = FALSE)), fixed = TRUE))) {
  stop("Rendered site is not using Quarto's supported Bootstrap 5.3.1 bundle")
}

for (feed in c("feed.xml", "feed-R.xml")) {
  if (!file.exists(file.path(root, "_site", feed))) stop("Missing compatibility feed: ", feed)
}
r_routes <- manifest$url[tolower(manifest$category) == "r"]
r_feed <- paste(readLines(file.path(root, "_site", "feed-R.xml"), warn = FALSE), collapse = "\n")
dated_links <- unique(regmatches(r_feed, gregexpr("https://fromthebottomoftheheap\\.net/[0-9]{4}/[0-9]{2}/[0-9]{2}/[^<\"]+/", r_feed, perl = TRUE))[[1L]])
dated_paths <- sub("^https://fromthebottomoftheheap\\.net", "", dated_links)
if (length(setdiff(dated_paths, r_routes))) stop("The R compatibility feed contains a non-R post")

link_status <- system2("python3", c("scripts/check-links.py", "_site"))
if (!identical(link_status, 0L)) stop("Rendered internal-link validation failed")

message("Validated 104 historical posts, 37 immutable Rmd archives, 386 baseline routes, feeds, Bootstrap, Giscus, and links.")
