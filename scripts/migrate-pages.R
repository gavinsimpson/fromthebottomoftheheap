#!/usr/bin/env Rscript

options(warn = 2)
root <- normalizePath(getwd(), mustWork = TRUE)
if (!requireNamespace("yaml", quietly = TRUE)) stop("The yaml package is required")

sources <- c(
  "404.md", "about/index.md", "code/dper-scripts/index.md",
  "code/dper-scripts/chapter-9-statistical-learning.md",
  "code/dper-scripts/chapter-15-analogue-methods.md",
  list.files("code/r-packages", pattern = "\\.md$", full.names = TRUE),
  "lab/index.md", "lab/join/index.md", "lab/members/index.md",
  "lab/publications/index.md", "lab/research/index.md",
  "publications/index.md", "publications/365papers/index.md",
  "publications/365papers/2016.md", "publications/365papers/2017.md",
  "research/index.md", "slides/index.md", "teaching/index.md"
  , "teaching/courses/mcmaster_2013/mcmaster_2013.md"
)

read_document <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (!length(lines) || trimws(lines[[1L]]) != "---" || !length(which(trimws(lines[-1L]) == "---"))) {
    fallback <- if (basename(path) == "index.md") tools::toTitleCase(basename(dirname(path))) else tools::toTitleCase(sub("\\.md$", "", basename(path)))
    return(list(metadata = list(title = fallback), body = lines))
  }
  end <- which(trimws(lines[-1L]) == "---")[[1L]] + 1L
  list(
    metadata = yaml::yaml.load(paste(lines[2L:(end - 1L)], collapse = "\n")),
    body = lines[(end + 1L):length(lines)]
  )
}

output_path <- function(path) {
  if (path == "404.md") return("404.qmd")
  if (basename(path) == "index.md") return(sub("\\.md$", ".qmd", path))
  file.path(dirname(path), sub("\\.md$", "", basename(path)), "index.qmd")
}

clean_body <- function(lines) {
  text <- paste(lines, collapse = "\n")
  text <- gsub("\\{\\{\\s*site\\.(url|baseurl)\\s*\\}\\}", "", text, perl = TRUE)
  text <- gsub("(?m)^\\{%\\s*highlight\\s+([^ %}]+)(?:\\s+linenos)?\\s*%\\}\\s*$", "```\\1", text, perl = TRUE)
  text <- gsub("(?m)^\\{%\\s*endhighlight\\s*%\\}\\s*$", "```", text, perl = TRUE)
  text <- gsub("\\{%\\s*include\\s+cc-by-icon\\.html\\s*%\\}", '<img class="licence-icon" src="/assets/img/cc-by.png" alt="Creative Commons Attribution">', text, perl = TRUE)
  text <- gsub("\\{%\\s*include\\s+cc-by-nc-icon\\.html\\s*%\\}", '<img class="licence-icon" src="/assets/img/cc-by-nc.png" alt="Creative Commons Attribution-NonCommercial">', text, perl = TRUE)
  text <- gsub('class="icon-file(?: addToolTip)?"(?: data-original-title="[^"]*")?(?: data-placement="[^"]*")?(?: data-animation="[^"]*")?', 'class="bi bi-file-earmark-pdf"', text, perl = TRUE)
  text <- gsub("/code/r-packages/analogue.html", "/code/r-packages/analogue/", text, fixed = TRUE)
  text <- gsub("/code/dper-scripts/chapter-9-statistical-learning.html", "/code/dper-scripts/chapter-9-statistical-learning/", text, fixed = TRUE)
  text <- gsub("/code/dper-scripts/chapter-15-analogue-methods.html", "/code/dper-scripts/chapter-15-analogue-methods/", text, fixed = TRUE)
  text <- gsub(
    "\\[Human Impacts: Applications of Numerical Methods to Evaluate Surface-Water Acidification and Eutrophication\\]\\(/code/dper-scripts/chapter-19-human-impacts.html\\)",
    "Human Impacts: Applications of Numerical Methods to Evaluate Surface-Water Acidification and Eutrophication (legacy script unavailable)",
    text,
    perl = TRUE
  )
  strsplit(text, "\n", fixed = TRUE)[[1L]]
}

for (source in sources) {
  parsed <- read_document(source)
  meta <- parsed$metadata
  if (!is.null(meta$title)) meta$title <- as.character(meta$title)
  if (!is.null(meta$tags)) meta$tags <- as.list(as.character(unlist(meta$tags)))
  for (field in c("layout", "active", "published", "status", "type")) meta[[field]] <- NULL
  meta$comments <- FALSE
  out <- output_path(source)
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  front <- strsplit(yaml::as.yaml(meta, indent.mapping.sequence = TRUE), "\n", fixed = TRUE)[[1L]]
  front <- sub(": no$", ": false", front)
  front <- sub(": yes$", ": true", front)
  writeLines(c("---", front, "---", "", clean_body(parsed$body)), out, useBytes = TRUE)
}

if (file.exists("permissions/index.html")) {
  permissions <- readLines("permissions/index.html", warn = FALSE)
  end <- which(trimws(permissions[-1L]) == "---")[[1L]] + 1L
  permissions <- permissions[(end + 1L):length(permissions)]
  permissions <- gsub("\\{\\{\\s*site\\.url\\s*\\}\\}", "", permissions, perl = TRUE)
  writeLines(c("---", "title: Permissions", "comments: false", "---", "", permissions), "permissions/index.qmd", useBytes = TRUE)
}

# This route existed only as rendered Jekyll output. Emit it directly so old
# links keep working, using the authoritative current publications content.
publications <- read_document("publications/index.md")
altmetrics_meta <- publications$metadata
for (field in c("layout", "active", "published", "status", "type")) altmetrics_meta[[field]] <- NULL
altmetrics_meta$title <- "Publications"
altmetrics_meta$comments <- FALSE
altmetrics_path <- "publications/with-altmetrics/index.qmd"
dir.create(dirname(altmetrics_path), recursive = TRUE, showWarnings = FALSE)
altmetrics_front <- strsplit(yaml::as.yaml(altmetrics_meta, indent.mapping.sequence = TRUE), "\n", fixed = TRUE)[[1L]]
altmetrics_front <- sub(": no$", ": false", altmetrics_front)
altmetrics_front <- sub(": yes$", ": true", altmetrics_front)
writeLines(c("---", altmetrics_front, "---", "", clean_body(publications$body)), altmetrics_path, useBytes = TRUE)

message("Converted ", length(sources) + 2L, " primary and compatibility pages to QMD.")
