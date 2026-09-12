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

post_descriptions <- vapply(dated_qmd, function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  yaml_end <- which(trimws(lines[-1L]) == "---")[[1L]] + 1L
  metadata <- yaml::yaml.load(paste(lines[2L:(yaml_end - 1L)], collapse = "\n"))
  if (is.null(metadata$description)) "" else as.character(metadata$description)
}, character(1L))
if (any(!nzchar(post_descriptions))) stop("Every historical post must have a listing description")
if (any(endsWith(post_descriptions, "…"))) stop("Historical post descriptions must not be truncated")

post_categories <- vapply(dated_qmd, function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  yaml_end <- which(trimws(lines[-1L]) == "---")[[1L]] + 1L
  metadata <- yaml::yaml.load(paste(lines[2L:(yaml_end - 1L)], collapse = "\n"))
  if (is.null(metadata$category)) "" else as.character(metadata$category)
}, character(1L))
if (any(tolower(manifest$category) == "science" & manifest$category != "Science", na.rm = TRUE) ||
    any(tolower(post_categories) == "science" & post_categories != "Science")) {
  stop("Science categories must use canonical capitalization")
}

leading_blank_fences <- dated_qmd[vapply(dated_qmd, function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^```[^[:space:]{]+[[:space:]]*$", lines, perl = TRUE)
  any(starts < length(lines) & !nzchar(trimws(lines[starts + 1L])))
}, logical(1L))]
if (length(leading_blank_fences)) {
  stop("Visible historical code fences start with a blank line: ", paste(leading_blank_fences, collapse = ", "))
}

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
home_text <- paste(home, collapse = "\n")
if (grepl('<a class="navbar-brand', home_text, fixed = TRUE)) stop("The redundant site title remains in the navbar")
home_sidebar_items <- c("Social", "Blogroll", "Buy Me A Coffee", "Musings on Quantitative Palaeoecology")
if (!all(vapply(home_sidebar_items, grepl, logical(1L), x = home_text, fixed = TRUE))) {
  stop("The home-page Social or Blogroll sidebar is incomplete")
}
if (!grepl("home-posts", home_text, fixed = TRUE) || !grepl("home-sidebar", home_text, fixed = TRUE)) {
  stop("The home-page wide listing layout is missing")
}
if (!grepl('class="home-posts">[[:space:][:print:]]*class="quarto-listing', home_text, perl = TRUE)) {
  stop("The home-page listing is not inside the wide listing column")
}
if (!grepl("Here, I describe what I broke as well as outline some of the major new features in the package.", home_text, fixed = TRUE)) {
  stop("The home-page listing does not contain the complete opening paragraph")
}

post_html <- file.path(root, "_site", sub("^/", "", manifest$url), "index.html")
post_sidebar_include <- "{{< include ../../../../includes/social-blogroll.qmd >}}"
if (!all(vapply(manifest$qmd, function(path) {
  any(grepl(post_sidebar_include, readLines(file.path(root, path), warn = FALSE), fixed = TRUE))
}, logical(1L)))) {
  stop("The shared Social and Blogroll sidebar is missing from a historical post source")
}
rendered <- unlist(lapply(post_html, function(path) readLines(path, warn = FALSE)), use.names = FALSE)
if (any(grepl('class="description"', rendered, fixed = TRUE))) {
  theme_text <- paste(readLines(file.path(root, "theme.scss"), warn = FALSE), collapse = "\n")
  if (!grepl("\\.quarto-title-block[[:space:]]+\\.description[[:space:]]*\\{[^}]*display:[[:space:]]*none", theme_text, perl = TRUE)) {
    stop("Post descriptions would be visible in the title block")
  }
}
if (any(grepl("assets/css/bootstrap.css|assets/js/bootstrap.js|class=.[^\"]*span[0-9]+", rendered))) {
  stop("Obsolete Bootstrap 2 assets or grid classes remain in rendered posts")
}
if (any(grepl("\\{%|\\{\\{", rendered))) stop("Unresolved Liquid syntax remains in rendered posts")
if (any(grepl("<p>[^\n]*\\*[[:space:]]+<(?:code|a|em|strong)", rendered, perl = TRUE))) {
  stop("A Markdown bullet marker was rendered literally inside a post paragraph")
}
if (any(grepl("\\([^)]*\\)\\[https?://[^]]+\\]", rendered, perl = TRUE))) {
  stop("A reversed Markdown link was rendered literally inside a post")
}
if (any(grepl("A historical post attempted to execute R code", rendered, fixed = TRUE))) {
  stop("The historical execution sentinel leaked into rendered output")
}
if (!all(vapply(post_html, function(path) any(grepl("giscus.app/client.js", readLines(path, warn = FALSE), fixed = TRUE)), logical(1L)))) {
  stop("Giscus is not enabled on every historical post")
}
if (!all(vapply(post_html, function(path) {
  lines <- readLines(path, warn = FALSE)
  all(vapply(c("buymeacoffee.com/gavinsimpson", ">Social</h4>", ">Blogroll</h4>"), function(value) {
    any(grepl(value, lines, fixed = TRUE))
  }, logical(1L)))
}, logical(1L)))) {
  stop("The rendered Social, Buy Me a Coffee, or Blogroll sidebar is missing from a historical post")
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

syntax_css <- list.files(file.path(root, "_site", "site_libs", "quarto-html"),
                         pattern = "quarto-syntax-highlighting-.*\\.css$", full.names = TRUE)
syntax_lines <- unlist(lapply(syntax_css, readLines, warn = FALSE))
monokai_tokens <- c("#f92672", "#e6db74", "#a6e22e", "#ae81ff")
if (!length(syntax_css) || !all(vapply(monokai_tokens, function(value) {
  any(grepl(value, syntax_lines, fixed = TRUE))
}, logical(1L)))) {
  stop("Rendered site does not use the expected Monokai syntax palette")
}

theme_lines <- readLines(file.path(root, "theme.scss"), warn = FALSE)
if (any(grepl("^code:not\\(\\.sourceCode\\)", theme_lines))) {
  stop("Inline-code styling must not apply to code inside preformatted blocks")
}
theme_text <- paste(theme_lines, collapse = "\n")
heading_theme_rules <- c(
  '\\$headings-font-family:[[:space:]]*"Open Sans Condensed"',
  "\\$headings-font-weight:[[:space:]]*300",
  "\\$headings-color:[[:space:]]*\\$primary",
  "h1,[[:space:]]*h2,[[:space:]]*h3,[[:space:]]*h4,[[:space:]]*h5,[[:space:]]*h6,[^}]*font-weight:[[:space:]]*300"
)
if (!all(vapply(heading_theme_rules, function(pattern) grepl(pattern, theme_text), logical(1L)))) {
  stop("Heading typography must retain the legacy orange Open Sans Condensed treatment")
}
if (grepl("h1,[[:space:]]*h2,[[:space:]]*h3[[:space:]]*\\{[^}]*color:[[:space:]]*#222", theme_text, perl = TRUE)) {
  stop("A dark heading rule overrides the legacy orange heading colour")
}
style_parity_rules <- c(
  "\\$font-size-root:[[:space:]]*16px",
  "\\$font-size-base:[[:space:]]*0?\\.875rem",
  "\\$line-height-base:[[:space:]]*1\\.428571429",
  "\\$body-color:[[:space:]]*#333333",
  "\\$link-color:[[:space:]]*\\$primary",
  "\\$link-hover-color:[[:space:]]*#ff7142",
  '\\$font-family-monospace:[[:space:]]*"Source Code Pro"',
  "h1,[[:space:]]*\\.h1[[:space:]]*\\{[^}]*font-size:[[:space:]]*38\\.5px",
  "h2,[[:space:]]*\\.h2[[:space:]]*\\{[^}]*font-size:[[:space:]]*31\\.5px",
  "h3,[[:space:]]*\\.h3[[:space:]]*\\{[^}]*font-size:[[:space:]]*24\\.5px",
  "pre:not\\(\\.sourceCode\\)[[:space:]]*\\{[^}]*padding:[[:space:]]*9\\.5px",
  "div\\.sourceCode[[:space:]]*>[[:space:]]*pre\\.sourceCode[[:space:]]*\\{[^}]*padding:[[:space:]]*9\\.5px",
  "pre code,[[:space:]]*pre\\.sourceCode code[[:space:]]*\\{[^}]*font-size:[[:space:]]*13px[^}]*line-height:[[:space:]]*20px",
  "blockquote[[:space:]]*\\{[^}]*border-right:[[:space:]]*5px[[:space:]]+solid[[:space:]]+#f43d00",
  "table,[[:space:]]*table\\.table[[:space:]]*\\{[^}]*margin-block:[[:space:]]*3em",
  "#blogroll[[:space:]]+\\.sidebar-links[[:space:]]*\\{[^}]*font-size:[[:space:]]*10px",
  "\\.buy-me-coffee[[:space:]]*\\{[^}]*height:[[:space:]]*45px[^}]*width:[[:space:]]*150px",
  "\\.nav-footer[[:space:]]*\\{[^}]*min-height:[[:space:]]*150px"
)
if (!all(vapply(style_parity_rules, function(pattern) grepl(pattern, theme_text, perl = TRUE), logical(1L)))) {
  stop("The Quarto theme has drifted from the legacy site's typography and component scale")
}
if (!grepl("pre:not\\(\\.sourceCode\\)[[:space:]]*\\{[^}]*padding:[[:space:]]*9\\.5px", theme_text, perl = TRUE) ||
    !grepl("div\\.sourceCode[[:space:]]*>[[:space:]]*pre\\.sourceCode[[:space:]]*\\{[^}]*padding:[[:space:]]*9\\.5px", theme_text, perl = TRUE)) {
  stop("Plain output blocks must match source-code block padding")
}
if (!grepl("\\.post-taxonomy[[:space:]]+\\.badge[[:space:]]*\\{[^}]*text-decoration:[[:space:]]*none", theme_text, perl = TRUE)) {
  stop("Post taxonomy pills must not be underlined")
}
if (!grepl("\\.quarto-title[[:space:]]+\\.quarto-categories[[:space:]]*\\{[^}]*display:[[:space:]]*none", theme_text, perl = TRUE)) {
  stop("The duplicate, unlinked Quarto category display must be hidden")
}
if (!grepl("\\.post-taxonomy[[:space:]]*>[[:space:]]*section[[:space:]]*\\{[^}]*display:[[:space:]]*flex", theme_text, perl = TRUE)) {
  stop("Post taxonomy headings and pills must use the compact inline layout")
}
if (!grepl("\\.post-taxonomy[[:space:]]*\\{[^}]*border-left:[[:space:]]*4px[[:space:]]+solid[[:space:]]+#f43d00", theme_text, perl = TRUE)) {
  stop("Consolidated post metadata must retain the orange left border")
}
if (!grepl("body:has\\(\\.post-taxonomy\\)[[:space:]]+#quarto-document-content[[:space:]]*>[[:space:]]*:not\\(\\.column-margin\\)[[:space:]]*\\{[^}]*grid-column:[[:space:]]*page-start[[:space:]]*/[[:space:]]*body-content-end", theme_text, perl = TRUE)) {
  stop("Desktop post content must align with the home-page listing edge")
}
metadata_script <- paste(readLines(file.path(root, "assets", "js", "post-metadata.js"), warn = FALSE), collapse = "\n")
if (!grepl("taxonomy.prepend(metadata)", metadata_script, fixed = TRUE)) {
  stop("Post author and date must move into the taxonomy block")
}
if (!grepl('.querySelector(".post-links .buy-me-coffee")', metadata_script, fixed = TRUE) ||
    !grepl("taxonomy.append(support)", metadata_script, fixed = TRUE)) {
  stop("The post Buy Me a Coffee button must move from Social into the taxonomy block")
}
if (!grepl("#quarto-document-content[[:space:]]+\\.post-links[[:space:]]*\\{[^}]*order:[[:space:]]*1", theme_text, perl = TRUE)) {
  stop("Post sidebar must follow the article content on narrow screens")
}

for (feed in c("feed.xml", "feed-R.xml")) {
  if (!file.exists(file.path(root, "_site", feed))) stop("Missing compatibility feed: ", feed)
}
for (feed in c("index.xml", "feed.xml", "feed-R/index.xml", "feed-R.xml")) {
  feed_text <- paste(readLines(file.path(root, "_site", feed), warn = FALSE), collapse = "\n")
  if (grepl('class="post-links"', feed_text, fixed = TRUE) ||
      grepl("buymeacoffee.com/gavinsimpson", feed_text, fixed = TRUE)) {
    stop("Post sidebar content leaked into feed: ", feed)
  }
}
r_routes <- manifest$url[tolower(manifest$category) == "r"]
r_feed <- paste(readLines(file.path(root, "_site", "feed-R.xml"), warn = FALSE), collapse = "\n")
dated_links <- unique(regmatches(r_feed, gregexpr("https://fromthebottomoftheheap\\.net/[0-9]{4}/[0-9]{2}/[0-9]{2}/[^<\"]+/", r_feed, perl = TRUE))[[1L]])
dated_paths <- sub("^https://fromthebottomoftheheap\\.net", "", dated_links)
if (length(setdiff(dated_paths, r_routes))) stop("The R compatibility feed contains a non-R post")

link_status <- system2("python3", c("scripts/check-links.py", "_site"))
if (!identical(link_status, 0L)) stop("Rendered internal-link validation failed")

html_files <- list.files(file.path(root, "_site"), pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
protocol_relative_links <- vapply(html_files, function(path) {
  any(grepl('href=["\\x27]//[^/]', readLines(path, warn = FALSE), perl = TRUE))
}, logical(1L))
if (any(protocol_relative_links)) {
  stop("Rendered pages contain protocol-relative internal links: ",
       paste(sub(paste0("^", root, "/_site/"), "", html_files[protocol_relative_links]), collapse = ", "))
}

message("Validated 104 historical posts, 37 immutable Rmd archives, 386 baseline routes, feeds, Bootstrap, Giscus, and links.")
