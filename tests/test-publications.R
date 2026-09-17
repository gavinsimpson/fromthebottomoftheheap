#!/usr/bin/env Rscript

source("scripts/publications.R")

assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}

assert_error <- function(expression, message) {
  failed <- inherits(try(force(expression), silent = TRUE), "try-error")
  assert(failed, message)
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
assert(identical(as.integer(cache$schema_version), 2L), "The publication cache must use schema version 2.")

featured <- unlist(registry$featured, use.names = FALSE)
expected_featured <- c(
  "miranda-velez-et-al-2026", "gerlich-et-al-2025",
  "turner-et-al-2024", "doi-10-1111-fwb-14192"
)
assert(identical(featured, expected_featured), "Featured publications must retain their configured display order.")
assert(length(featured) <= 4L && !anyDuplicated(featured), "Featured publications must be unique and limited to four.")
validate_featured_publications(registry, cache)

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
selector_tmp <- tempfile(fileext = ".md")
on.exit(unlink(c(tmp, selector_tmp)), add = TRUE)
invisible(render_publications_markdown(registry, cache, tmp, selector_tmp))
generated <- readLines(tmp, warn = FALSE)
generated_selector <- readLines(selector_tmp, warn = FALSE)
published_years <- unique(vapply(seq_along(entries), function(i) {
  if (nzchar(entries[[i]]$status %||% "")) return("")
  as.character(entries[[i]]$year %||% if (is.null(metadata[[i]])) "" else date_year(metadata[[i]]))
}, character(1)))
published_years <- published_years[nzchar(published_years)]
assert(sum(grepl("data-publication-id=", generated, fixed = TRUE)) == length(entries),
  "Generated year lists must contain exactly one item per publication.")
assert(!any(grepl("<strong>94 publications</strong>", generated, fixed = TRUE)) &&
    any(grepl("<strong>94 publications</strong>", generated_selector, fixed = TRUE)),
  "The generated sidebar must show the total publication count.")
assert(!any(grepl("publication-year-selector", generated, fixed = TRUE)) &&
    any(grepl("publication-year-selector", generated_selector, fixed = TRUE)) &&
    length(grep('class="dropdown-item" href="#year-', generated_selector, fixed = TRUE)) == length(published_years),
  "The generated year selector must be separate from the main publication content.")
assert(any(grepl('href="#unpublished">Unpublished (', generated_selector, fixed = TRUE)) &&
    !any(grepl("dropdown-divider", generated_selector, fixed = TRUE)) &&
    any(grepl('id="unpublished"', generated, fixed = TRUE)),
  "Unpublished publications must be presented like the year groups.")
assert(any(grepl("<div class=\"featured-publications\">", generated, fixed = TRUE)),
  "Featured cards must render in the single-column featured list.")
assert(sum(grepl("row g-0 h-100 featured-publication-layout", generated, fixed = TRUE)) == length(featured) &&
    sum(grepl("class=\"featured-publication-media\"", generated, fixed = TRUE)) == length(featured) &&
    sum(grepl("class=\"featured-publication-content\"", generated, fixed = TRUE)) == length(featured),
  "Featured thumbnails must sit beside card text at every screen width.")
assert(!any(grepl("featured-publication-publisher", generated, fixed = TRUE)),
  "Featured cards must not duplicate their linked title with a publisher button.")
assert(sum(grepl("class=\"featured-publication-controls\"", generated, fixed = TRUE)) == length(featured) &&
    sum(grepl("aria-label=\"Download PDF\"", generated, fixed = TRUE)) == length(featured) &&
    !any(grepl('aria-label="Download PDF".*> PDF</a>', generated)),
  "Every featured card must render an icon-only PDF control beneath its thumbnail.")
assert(sum(grepl("featured-publication-title", generated, fixed = TRUE)) == length(featured) &&
    sum(grepl("featured-publication-details", generated, fixed = TRUE)) == length(featured) &&
    sum(grepl("featured-publication-doi", generated, fixed = TRUE)) == length(featured),
  "Every featured card must render the explicit title and metadata typography hooks.")
assert(!any(grepl("featured-publication-actions", generated, fixed = TRUE)),
  "Featured card controls must not remain in the bibliographic text column.")
assert(sum(grepl("<article class=\"card h-100 featured-publication\"", generated, fixed = TRUE)) == length(featured),
  "Every configured featured publication must render one Bootstrap card.")
assert(sum(grepl("data-bs-toggle=\"modal\" data-bs-target=\"#abstract-", generated, fixed = TRUE)) == length(featured) &&
    sum(grepl("modal-dialog modal-xl modal-dialog-centered", generated, fixed = TRUE)) == length(featured) &&
    sum(grepl("data-bs-dismiss=\"modal\"", generated, fixed = TRUE)) == 2L * length(featured),
  "Every featured card must render a centred, scrollable abstract modal with two close controls.")
assert(sum(grepl('class="modal-title h4"', generated, fixed = TRUE)) == length(featured) &&
    sum(grepl('class="featured-publication-modal-title"><a href="https://doi.org/', generated, fixed = TRUE)) == length(featured),
  "Every featured modal must render a prominent heading and a DOI-linked publication title.")
assert(sum(grepl('class="featured-publication-modal-authors"', generated, fixed = TRUE)) == length(featured) &&
    sum(grepl('class="btn btn-outline-secondary featured-publication-modal-pdf"', generated, fixed = TRUE)) == length(featured),
  "Every featured modal must render its full author list and a PDF footer button.")
long_featured_authors <- sum(vapply(featured, function(id) {
  length(metadata[[match(id, ids)]]$author %||% list()) > 4L
}, logical(1)))
assert(sum(grepl("featured-publication-authors-more", generated, fixed = TRUE)) == long_featured_authors,
  "Every featured author list longer than four must render one linked ellipsis.")
sample_people <- lapply(seq_len(6L), function(i) list(family = paste0("Author", i), given = "A"))
sample_authors <- format_featured_people(sample_people, list(family = "Nobody"), "sample")
assert(all(vapply(seq_len(6L), function(i) {
  length(gregexpr(paste0("Author", i), sample_authors, fixed = TRUE)[[1L]]) == 1L
}, logical(1))) && grepl("authors-sample", sample_authors, fixed = TRUE) &&
    grepl('aria-label="Show remaining authors">…</a>', sample_authors, fixed = TRUE) &&
    grepl("featured-publication-authors-less", sample_authors, fixed = TRUE) &&
    grepl("bi-chevron-up", sample_authors, fixed = TRUE),
  "Expanded featured author lists must append only the omitted authors and end with a collapse control.")
assert(sum(grepl("class=\"publication-group\"", generated, fixed = TRUE)) == length(unique(vapply(seq_along(entries), function(i) {
  if (nzchar(entries[[i]]$status %||% "")) "current-work" else date_year(metadata[[i]])
}, character(1)))), "Every populated publication section must render once.")

listed_ids <- sub('.*data-publication-id="([^"]+)".*', "\\1", generated[grepl("data-publication-id=", generated, fixed = TRUE)])
assert(setequal(listed_ids, ids) && !anyDuplicated(listed_ids), "Each publication must occur exactly once in the main bibliography.")

thumbnail_files <- file.path(paths$thumbnails, paste0(featured, ".webp"))
assert(all(file.exists(thumbnail_files)), "Every featured publication must have a generated WebP thumbnail.")
assert(setequal(list.files(paths$thumbnails, pattern = "[.]webp$"), basename(thumbnail_files)),
  "The thumbnail directory must not contain obsolete WebP files.")
thumbnail_info <- magick::image_info(magick::image_read(thumbnail_files))
assert(all(thumbnail_info$format == "WEBP") && all(thumbnail_info$width == 720L),
  "Featured thumbnails must be 720-pixel-wide WebP images.")

assert(identical(clean_abstract("<jats:p>A <jats:italic>short</jats:italic> abstract.</jats:p>"), "A short abstract."),
  "JATS cleanup must retain inline word boundaries without markup.")
assert(identical(publication_metadata(registry$entries[[match("miranda-velez-et-al-2026", ids)]], cache)$abstract,
  registry$entries[[match("miranda-velez-et-al-2026", ids)]]$overrides$abstract),
  "A YAML abstract override must take precedence over cached metadata.")
assert(sum(grepl("file-earmark-pdf", generated, fixed = TRUE)) >= 59L, "All 59 migrated publication manuscript/reprint links must be preserved.")
assert(sum(grepl("publication-licence", generated, fixed = TRUE)) >= 35L, "All 35 migrated licences must be preserved.")
assert(sum(grepl("fa brands creative-commons-by", generated, fixed = TRUE)) >= 35L,
  "Every rendered publication licence must include the Font Awesome attribution icon.")
assert(any(grepl("fa brands creative-commons-nc", generated, fixed = TRUE)),
  "CC BY-NC publications must include the Font Awesome non-commercial icon.")

suggestions <- yaml::read_yaml(paths$suggestions)
assert(is.list(suggestions) && is.list(suggestions$suggestions), "Version-of-record suggestions must be valid YAML.")
assert(any(vapply(entries, function(x) isTRUE(x$check_for_version_of_record), logical(1))),
  "At least one migrated preprint should exercise version-of-record monitoring.")

original_fetch <- fetch_doi_metadata
original_abstract_fetch <- fetch_crossref_abstract
fetch_doi_metadata <- function(doi) stop("Network access should not occur for a complete cache.")
fetch_crossref_abstract <- function(doi) stop("Abstract network access should not occur for a complete cache.")
invisible(refresh_publication_cache(registry, paths$cache, refresh_all = FALSE))
fetch_doi_metadata <- original_fetch
fetch_crossref_abstract <- original_abstract_fetch

abstract_registry <- registry
abstract_id <- "gerlich-et-al-2025"
abstract_cache <- cache
abstract_cache$records[[abstract_id]]$metadata$abstract <- NULL
abstract_path <- tempfile(fileext = ".json")
writeLines(canonical_json(abstract_cache), abstract_path, useBytes = TRUE)
fetch_crossref_abstract <- function(doi) clean_abstract("<jats:p>Retrieved abstract.</jats:p>")
refreshed <- refresh_publication_cache(abstract_registry, abstract_path, refresh_all = FALSE)$cache
fetch_crossref_abstract <- original_abstract_fetch
unlink(abstract_path)
assert(identical(refreshed$records[[abstract_id]]$metadata$abstract, "Retrieved abstract."),
  "A missing featured abstract must be fetched and cached.")

invalid_registry <- registry
invalid_registry$featured <- ids[seq_len(5L)]
assert_error(validate_publication_registry(invalid_registry), "More than four featured publications must fail validation.")

override_test <- merge_metadata(list(title = "Publisher title", page = "1-2"), list(title = "Corrected title"))
assert(identical(override_test$title, "Corrected title") && identical(override_test$page, "1-2"),
  "Registry overrides must take precedence without removing other metadata.")

source_files <- c("scripts/publications.R", "scripts/prepare-publications.R", "scripts/refresh-publications.R")
source_text <- paste(unlist(lapply(source_files, readLines, warn = FALSE), use.names = FALSE), collapse = "\n")
assert(!grepl("orcid", source_text, ignore.case = TRUE), "The publication pipeline must not use ORCID.")

cat("Publication tests passed.\n")
