#!/usr/bin/env Rscript

source("scripts/publications.R")

assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}

paths <- publication_paths()
registry <- read_publication_registry(paths$registry)
validate_publication_registry(registry)
cache <- read_publication_cache(paths$cache)

entries <- registry$entries
ids <- vapply(entries, function(x) x$id, character(1))
doi_entries <- vapply(entries, function(x) nzchar(normalize_doi(x$doi)), logical(1))

assert(length(entries) >= 88L, "The registry must retain all 88 migrated publications.")
assert(length(cache$records) == sum(doi_entries), "Every DOI entry must have one cached metadata record.")
assert(setequal(names(cache$records), ids[doi_entries]), "The cache contains missing or orphaned publication records.")

for (entry in entries[doi_entries]) {
  cached <- cache$records[[entry$id]]
  assert(identical(normalize_doi(cached$doi), normalize_doi(entry$doi)), paste("Cache DOI mismatch for", entry$id))
}

metadata <- lapply(entries, publication_metadata, cache = cache)
assert(all(vapply(metadata, function(x) !is.null(x), logical(1)) | vapply(entries, function(x) scalar_character(x$fallback_markdown), logical(1))),
  "Every publication must have cached/manual metadata or a Markdown fallback.")

owner <- registry$owner
for (i in seq_along(entries)) {
  if (is.null(metadata[[i]])) {
    assert(grepl("[*][*]Simpson", entries[[i]]$fallback_markdown), paste("Manual publication does not highlight the owner:", entries[[i]]$id))
  } else {
    authors <- metadata[[i]]$author %||% list()
    is_owner <- vapply(authors, function(x) identical(tolower(x$family %||% ""), tolower(owner$family)), logical(1))
    assert(any(is_owner), paste("DOI metadata does not identify the owner:", entries[[i]]$id))
    rendered <- format_publication(metadata[[i]], entries[[i]], owner)
    assert(grepl("<strong>[Ss]impson", rendered), paste("Rendered publication does not highlight the owner:", entries[[i]]$id))
  }
}

tmp <- tempfile(fileext = ".md")
on.exit(unlink(tmp), add = TRUE)
invisible(render_publications_markdown(registry, cache, tmp))
generated <- readLines(tmp, warn = FALSE)
assert(sum(grepl("^1[.] ", generated)) == length(entries), "Generated list must contain exactly one item per publication.")
assert(sum(grepl("file-earmark-pdf", generated, fixed = TRUE)) >= 59L, "All 59 migrated publication manuscript/reprint links must be preserved.")
assert(sum(grepl("licence-icon", generated, fixed = TRUE)) >= 35L, "All 35 migrated licence icons must be preserved.")

suggestions <- yaml::read_yaml(paths$suggestions)
assert(is.list(suggestions) && is.list(suggestions$suggestions), "Version-of-record suggestions must be valid YAML.")
assert(any(vapply(entries, function(x) isTRUE(x$check_for_version_of_record), logical(1))),
  "At least one migrated preprint should exercise version-of-record monitoring.")

original_fetch <- fetch_doi_metadata
fetch_doi_metadata <- function(doi) stop("Network access should not occur for a complete cache.")
invisible(refresh_publication_cache(registry, paths$cache, refresh_all = FALSE))
fetch_doi_metadata <- original_fetch

override_test <- merge_metadata(list(title = "Publisher title", page = "1-2"), list(title = "Corrected title"))
assert(identical(override_test$title, "Corrected title") && identical(override_test$page, "1-2"),
  "Registry overrides must take precedence without removing other metadata.")

source_files <- c("scripts/publications.R", "scripts/prepare-publications.R", "scripts/refresh-publications.R")
source_text <- paste(unlist(lapply(source_files, readLines, warn = FALSE), use.names = FALSE), collapse = "\n")
assert(!grepl("orcid", source_text, ignore.case = TRUE), "The publication pipeline must not use ORCID.")

cat("Publication tests passed.\n")
