# Quarto's listing dependency cache is populated by a complete project render.
# Focused builds are for edits to existing posts. Inventory changes (publishing,
# adding/removing a post, changing taxonomy membership) need a full build so
# removed archive routes and global indexes are cleaned up together.
archive_fingerprints <- function(root = getwd()) {
  paths <- c("index.qmd", "feed-R/index.qmd", unlist(lapply(
    c("blog", "category", "tag"), function(directory) {
      file.path(directory, list.files(file.path(root, directory),
        pattern = "^index\\.qmd$", recursive = TRUE))
    }
  ), use.names = FALSE))
  paths <- sort(paths[file.exists(file.path(root, paths))])
  stats::setNames(unname(tools::md5sum(file.path(root, paths))), paths)
}

focused_build_problem <- function(before, after, root = getwd()) {
  if (!identical(before, after)) {
    return("The published inventory or generated archives changed.")
  }
  if (!all(file.exists(file.path(root, "_site", c(
    "index.html", "search.json", "sitemap.xml", "listings.json"
  ))))) return("The existing rendered site is incomplete.")
  cache_path <- file.path(root, ".quarto", "listing", "listing-cache.json")
  cache <- tryCatch(jsonlite::fromJSON(cache_path), error = function(error) NULL)
  if (!all(names(after) %in% names(cache$listingMap))) {
    return("Quarto's listing dependency cache is missing or incomplete.")
  }
  for (path in names(after)) {
    contents <- unlist(read_qmd_metadata(file.path(root, path))$listing$contents, use.names = FALSE)
    if (!setequal(contents, cache$listingMap[[path]])) {
      return("Quarto's listing dependency cache does not match the current archives.")
    }
    output <- file.path(root, "_site", sub("\\.qmd$", ".html", path))
    if (!file.exists(output)) return("A rendered archive is missing.")
  }
  NULL
}

post_listing_inputs <- function(post, archives, root = getwd()) {
  target <- normalizePath(file.path(root, post), mustWork = TRUE)
  archives[vapply(archives, function(path) {
    contents <- unlist(read_qmd_metadata(file.path(root, path))$listing$contents, use.names = FALSE)
    inputs <- normalizePath(file.path(root, dirname(path), contents), mustWork = FALSE)
    target %in% inputs
  }, logical(1L))]
}
