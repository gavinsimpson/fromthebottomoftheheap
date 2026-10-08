# The dated QMD sources are the live post inventory. The migration manifest
# describes historical content only and must not determine current listings.
read_qmd_metadata <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  delimiters <- which(trimws(lines) == "---")
  if (length(delimiters) < 2L || delimiters[[1L]] != 1L) {
    stop("Missing YAML front matter in ", path)
  }
  yaml::yaml.load(paste(lines[seq.int(2L, delimiters[[2L]] - 1L)], collapse = "\n"))
}

post_values <- function(...) {
  values <- trimws(as.character(unlist(list(...), use.names = FALSE)))
  unique(values[!is.na(values) & nzchar(values)])
}

discover_posts <- function(root = getwd(), include_drafts = FALSE) {
  paths <- list.files(root, pattern = "^index\\.qmd$", recursive = TRUE)
  paths <- sort(paths[grepl("^[0-9]{4}/[0-9]{2}/[0-9]{2}/[^/]+/index\\.qmd$", paths)])
  metadata <- lapply(file.path(root, paths), read_qmd_metadata)
  drafts <- vapply(metadata, function(x) isTRUE(x$draft), logical(1L))
  keep <- include_drafts | !drafts
  paths <- paths[keep]
  metadata <- metadata[keep]
  posts <- data.frame(
    qmd = paths,
    url = if (length(paths)) paste0("/", sub("index\\.qmd$", "", paths)) else character(),
    year = as.integer(substr(paths, 1L, 4L)),
    stringsAsFactors = FALSE
  )
  posts$metadata <- I(metadata)
  posts$categories <- I(lapply(metadata, function(x) post_values(x$category, x$categories)))
  posts$tags <- I(lapply(metadata, function(x) post_values(x$tags)))
  posts
}

post_taxonomy <- function(posts, field) {
  rows <- lapply(seq_len(nrow(posts)), function(i) {
    values <- posts[[field]][[i]]
    if (!length(values)) return(NULL)
    data.frame(value = values, row = i, stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, rows)
  if (is.null(result)) data.frame(value = character(), row = integer()) else result
}

r_post_paths <- function(posts) {
  posts$qmd[vapply(posts$categories, function(values) any(tolower(values) == "r"), logical(1L))]
}
