`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

publication_paths <- function(root = ".") {
  list(
    registry = file.path(root, "publications", "publications.yml"),
    cache = file.path(root, "publications", "doi-cache.json"),
    suggestions = file.path(root, "publications", "doi-suggestions.yml"),
    generated = file.path(root, "publications", "_generated-publications.md")
  )
}

normalize_doi <- function(x) {
  x <- trimws(x %||% "")
  x <- sub("^https?://(dx[.])?doi[.]org/", "", x, ignore.case = TRUE)
  x <- sub("^doi:[[:space:]]*", "", x, ignore.case = TRUE)
  tolower(x)
}

read_publication_registry <- function(path) {
  registry <- yaml::read_yaml(path)
  if (!is.list(registry) || !is.list(registry$entries)) {
    stop("Publication registry must contain an 'entries' list: ", path)
  }
  registry
}

read_publication_cache <- function(path) {
  if (!file.exists(path)) {
    return(list(schema_version = 1L, records = list()))
  }
  cache <- jsonlite::read_json(path, simplifyVector = FALSE)
  cache$records <- cache$records %||% list()
  cache
}

scalar_character <- function(x) {
  is.character(x) && length(x) == 1L && nzchar(x)
}

validate_publication_registry <- function(registry, root = ".") {
  entries <- registry$entries
  ids <- vapply(entries, function(x) x$id %||% "", character(1))
  if (any(!nzchar(ids))) stop("Every publication needs a non-empty id.")
  if (anyDuplicated(ids)) {
    stop("Duplicate publication ids: ", paste(unique(ids[duplicated(ids)]), collapse = ", "))
  }

  dois <- vapply(entries, function(x) normalize_doi(x$doi), character(1))
  nonempty_dois <- dois[nzchar(dois)]
  if (anyDuplicated(nonempty_dois)) {
    stop("Duplicate publication DOIs: ", paste(unique(nonempty_dois[duplicated(nonempty_dois)]), collapse = ", "))
  }

  valid_status <- c("submitted", "in review", "in revision", "accepted", "in press", "preprint")
  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    has_doi <- nzchar(dois[[i]])
    has_manual <- is.list(entry$manual)
    has_fallback <- scalar_character(entry$fallback_markdown)
    if (!has_doi && !has_manual && !has_fallback) {
      stop("Publication '", ids[[i]], "' needs a DOI, manual CSL metadata, or fallback_markdown.")
    }
    if (!is.null(entry$status) && !entry$status %in% valid_status) {
      stop("Publication '", ids[[i]], "' has an unsupported status: ", entry$status)
    }
    if (isTRUE(entry$check_for_version_of_record) && !has_doi) {
      stop("Publication '", ids[[i]], "' cannot check for a version of record without a DOI.")
    }
    for (link in entry$links %||% list()) {
      if (!scalar_character(link$url)) stop("Publication '", ids[[i]], "' has a link without a URL.")
      if (startsWith(link$url, "/")) {
        local_path <- file.path(root, sub("^/", "", link$url))
        if (!file.exists(local_path)) stop("Missing local publication file: ", local_path)
      }
    }
    if (!is.null(entry$license$icon) && startsWith(entry$license$icon, "/")) {
      icon_path <- file.path(root, sub("^/", "", entry$license$icon))
      if (!file.exists(icon_path)) stop("Missing publication licence icon: ", icon_path)
    }
  }
  invisible(registry)
}

normalize_name <- function(person) {
  keep <- intersect(c("family", "given", "literal", "suffix", "non-dropping-particle", "dropping-particle"), names(person))
  person[keep]
}

normalize_csl_metadata <- function(metadata, doi = NULL) {
  fields <- c(
    "type", "title", "author", "editor", "issued", "published-print",
    "published-online", "container-title", "collection-title", "volume",
    "issue", "page", "article-number", "publisher", "publisher-place",
    "edition", "genre", "language", "ISBN", "ISSN", "DOI", "URL"
  )
  out <- metadata[intersect(fields, names(metadata))]
  if (is.list(out$author)) out$author <- lapply(out$author, normalize_name)
  if (is.list(out$editor)) out$editor <- lapply(out$editor, normalize_name)
  out$DOI <- normalize_doi(doi %||% out$DOI)
  out
}

fetch_doi_metadata <- function(doi) {
  doi <- normalize_doi(doi)
  request <- httr2::request(paste0("https://doi.org/", utils::URLencode(doi, reserved = TRUE))) |>
    httr2::req_headers(Accept = "application/vnd.citationstyles.csl+json") |>
    httr2::req_user_agent("fromthebottomoftheheap-publications/1.0 (mailto:ucfagls@gmail.com)") |>
    httr2::req_timeout(30) |>
    httr2::req_retry(max_tries = 3)
  response <- httr2::req_perform(request)
  normalize_csl_metadata(httr2::resp_body_json(response, simplifyVector = FALSE), doi)
}

canonical_json <- function(x) {
  paste0(jsonlite::toJSON(
    x,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  ), "\n")
}

write_text_if_changed <- function(text, path) {
  old <- if (file.exists(path)) paste0(readLines(path, warn = FALSE), collapse = "\n") else NULL
  new <- sub("\n$", "", text)
  if (identical(old, new)) return(FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(pattern = basename(path), tmpdir = dirname(path))
  on.exit(unlink(tmp), add = TRUE)
  writeLines(new, tmp, useBytes = TRUE)
  if (!file.rename(tmp, path)) stop("Could not replace ", path)
  TRUE
}

refresh_publication_cache <- function(registry, cache_path, refresh_all = FALSE) {
  cache <- read_publication_cache(cache_path)
  failures <- character()
  expected_ids <- vapply(registry$entries, function(entry) {
    if (nzchar(normalize_doi(entry$doi))) entry$id else ""
  }, character(1))
  expected_ids <- expected_ids[nzchar(expected_ids)]
  cache$records <- cache$records[intersect(names(cache$records), expected_ids)]

  for (entry in registry$entries) {
    doi <- normalize_doi(entry$doi)
    if (!nzchar(doi)) next
    cached <- cache$records[[entry$id]]
    needs_fetch <- refresh_all || is.null(cached) || !identical(normalize_doi(cached$doi), doi)
    if (!needs_fetch) next

    message(if (refresh_all) "Refreshing " else "Fetching ", doi)
    metadata <- tryCatch(fetch_doi_metadata(doi), error = identity)
    if (inherits(metadata, "error")) {
      if (!is.null(cached) || scalar_character(entry$fallback_markdown)) {
        warning("Could not refresh ", doi, "; retaining available local data: ", conditionMessage(metadata))
      } else {
        failures <- c(failures, paste0(doi, ": ", conditionMessage(metadata)))
      }
      next
    }
    cache$records[[entry$id]] <- list(doi = doi, metadata = metadata)
  }

  if (length(failures)) {
    stop("Could not fetch uncached DOI metadata:\n- ", paste(failures, collapse = "\n- "))
  }
  cache$schema_version <- 1L
  cache$records <- cache$records[sort(names(cache$records))]
  changed <- write_text_if_changed(canonical_json(cache), cache_path)
  list(cache = cache, changed = changed)
}

extract_related_dois <- function(items, relation_names, relation_field = "relationType") {
  if (!is.list(items) || !length(items)) return(character())
  values <- unlist(lapply(items, function(item) {
    relation <- tolower(item[[relation_field]] %||% "")
    id_type <- tolower(item[["id-type"]] %||% item$relatedIdentifierType %||% "")
    id <- item$id %||% item$relatedIdentifier %||% ""
    if (relation %in% tolower(relation_names) && id_type == "doi") normalize_doi(id) else NULL
  }), use.names = FALSE)
  unique(values[nzchar(values)])
}

fetch_version_of_record_dois <- function(doi) {
  doi <- normalize_doi(doi)
  encoded <- utils::URLencode(doi, reserved = TRUE)
  user_agent <- "fromthebottomoftheheap-publications/1.0 (mailto:ucfagls@gmail.com)"

  crossref <- httr2::request(paste0("https://api.crossref.org/works/", encoded)) |>
    httr2::req_url_query(mailto = "ucfagls@gmail.com") |>
    httr2::req_user_agent(user_agent) |>
    httr2::req_timeout(30) |>
    httr2::req_error(is_error = function(response) FALSE) |>
    httr2::req_perform()
  if (httr2::resp_status(crossref) == 200L) {
    relation <- httr2::resp_body_json(crossref, simplifyVector = FALSE)$message$relation %||% list()
    items <- c(relation[["is-preprint-of"]] %||% list(), relation[["is-version-of"]] %||% list())
    items <- lapply(items, function(item) {
      item$relationType <- "is-preprint-of"
      item
    })
    return(extract_related_dois(items, c("is-preprint-of", "is-version-of"), relation_field = "relationType"))
  }

  datacite <- httr2::request(paste0("https://api.datacite.org/dois/", encoded)) |>
    httr2::req_user_agent(user_agent) |>
    httr2::req_timeout(30) |>
    httr2::req_error(is_error = function(response) FALSE) |>
    httr2::req_perform()
  if (httr2::resp_status(datacite) == 200L) {
    related <- httr2::resp_body_json(datacite, simplifyVector = FALSE)$data$attributes$relatedIdentifiers %||% list()
    return(extract_related_dois(related, c("IsPreprintOf", "IsVersionOf")))
  }
  character()
}

refresh_version_of_record_suggestions <- function(registry, path) {
  suggestions <- list()
  for (entry in registry$entries) {
    if (!isTRUE(entry$check_for_version_of_record)) next
    message("Checking version-of-record relationships for ", entry$doi)
    related <- tryCatch(fetch_version_of_record_dois(entry$doi), error = function(error) {
      warning("Could not check relationships for ", entry$doi, ": ", conditionMessage(error))
      character()
    })
    related <- setdiff(related, normalize_doi(entry$doi))
    for (doi in related) {
      suggestions[[length(suggestions) + 1L]] <- list(
        publication_id = entry$id,
        current_doi = normalize_doi(entry$doi),
        suggested_version_of_record_doi = doi
      )
    }
  }
  document <- list(
    note = "Review these relationships, then update publications.yml; this file is generated by the weekly refresh.",
    suggestions = suggestions
  )
  write_text_if_changed(yaml::as.yaml(document), path)
}

merge_metadata <- function(metadata, overrides) {
  if (is.null(overrides)) return(metadata)
  for (field in names(overrides)) metadata[[field]] <- overrides[[field]]
  metadata
}

publication_metadata <- function(entry, cache) {
  cached <- cache$records[[entry$id]]
  metadata <- if (!is.null(cached)) cached$metadata else entry$manual
  if (is.null(metadata)) return(NULL)
  metadata <- merge_metadata(metadata, entry$overrides)
  metadata$id <- entry$id
  if (!is.null(entry$status)) metadata$status <- entry$status
  metadata
}

html_escape <- function(x, attribute = FALSE) {
  x <- paste(x %||% "", collapse = " ")
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  if (attribute) x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

safe_csl_text <- function(x) {
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- html_escape(x)
  allowed <- c("i", "b", "em", "strong", "sub", "sup")
  for (tag in allowed) {
    x <- gsub(paste0("&lt;", tag, "&gt;"), paste0("<", tag, ">"), x, fixed = TRUE)
    x <- gsub(paste0("&lt;/", tag, "&gt;"), paste0("</", tag, ">"), x, fixed = TRUE)
  }
  x
}

initials <- function(given) {
  if (!scalar_character(given)) return("")
  parts <- unlist(strsplit(trimws(given), "[^[:alpha:]]+"))
  parts <- parts[nzchar(parts)]
  chars <- vapply(parts, function(x) substring(gsub("^[^[:alpha:]]+", "", x), 1L, 1L), character(1))
  chars <- chars[nzchar(chars)]
  paste0(toupper(chars), ".", collapse = " ")
}

format_person <- function(person, owner) {
  if (scalar_character(person$literal)) return(safe_csl_text(person$literal))
  family <- paste(c(person$`non-dropping-particle`, person$family), collapse = " ")
  family <- trimws(family)
  if (nzchar(family) && identical(family, toupper(family))) family <- tools::toTitleCase(tolower(family))
  label <- paste0(safe_csl_text(family), if (nzchar(initials(person$given))) paste0(", ", initials(person$given)) else "")
  is_owner <- identical(tolower(person$family %||% ""), tolower(owner$family %||% "")) &&
    (is.null(owner$given_initial) || startsWith(tolower(person$given %||% ""), tolower(owner$given_initial)))
  if (is_owner) paste0("<strong>", label, "</strong>") else label
}

format_people <- function(people, owner) {
  if (!is.list(people) || !length(people)) return("")
  labels <- vapply(people, format_person, character(1), owner = owner)
  if (length(labels) == 1L) return(labels)
  if (length(labels) == 2L) return(paste(labels, collapse = " &amp; "))
  paste0(paste(labels[-length(labels)], collapse = ", "), ", &amp; ", labels[[length(labels)]])
}

date_year <- function(metadata) {
  candidates <- list(metadata$`published-print`, metadata$issued, metadata$`published-online`)
  for (candidate in candidates) {
    parts <- candidate$`date-parts` %||% NULL
    if (is.list(parts) && length(parts) && length(parts[[1L]])) return(as.character(parts[[1L]][[1L]]))
  }
  ""
}

field_text <- function(x) {
  if (is.null(x)) return("")
  if (is.list(x) && !is.data.frame(x)) x <- unlist(x, use.names = FALSE)
  paste(x, collapse = "; ")
}

sentence <- function(x) {
  x <- trimws(x)
  if (!nzchar(x)) return("")
  if (grepl("[.!?]$", x)) x else paste0(x, ".")
}

format_publication <- function(metadata, entry, owner) {
  authors <- format_people(metadata$author, owner)
  when <- entry$status %||% date_year(metadata)
  prefix <- paste0(authors, if (nzchar(when)) paste0(" (", html_escape(when), ")") else "")

  title <- safe_csl_text(sub("[[:space:].]+$", "", field_text(metadata$title)))
  doi <- normalize_doi(entry$doi %||% metadata$DOI)
  url <- if (nzchar(doi)) paste0("https://doi.org/", doi) else field_text(metadata$URL)
  linked_title <- if (nzchar(url)) {
    paste0('<a href="', html_escape(url, attribute = TRUE), '">', title, "</a>")
  } else title

  container <- safe_csl_text(field_text(metadata$`container-title`))
  volume <- safe_csl_text(field_text(metadata$volume))
  issue <- safe_csl_text(field_text(metadata[["issue"]]))
  pages <- safe_csl_text(field_text(metadata[["page"]] %||% metadata[["article-number"]]))
  pages <- gsub("-", "&ndash;", pages, fixed = TRUE)
  publisher <- safe_csl_text(field_text(metadata$publisher))
  place <- safe_csl_text(field_text(metadata$`publisher-place`))
  type <- metadata$type %||% ""

  details <- character()
  if (type %in% c("book-chapter", "chapter", "entry-encyclopedia")) {
    editors <- format_people(metadata$editor, owner)
    if (nzchar(container)) {
      details <- c(details, paste0("In ", if (nzchar(editors)) paste0(editors, " (Eds.), ") else "", "<em>", container, "</em>"))
    }
    publisher_details <- paste(c(publisher, place)[nzchar(c(publisher, place))], collapse = ", ")
    if (nzchar(publisher_details)) details <- c(details, publisher_details)
    if (nzchar(pages)) details <- c(details, paste0("pp. ", pages))
  } else {
    if (nzchar(container)) details <- c(details, paste0("<em>", container, "</em>"))
    journal_details <- paste0(
      if (nzchar(volume)) paste0("<strong>", volume, "</strong>") else "",
      if (nzchar(issue)) paste0("(", issue, ")") else "",
      if (nzchar(pages)) paste0(if (nzchar(volume) || nzchar(issue)) ", " else "", pages) else ""
    )
    if (nzchar(journal_details)) details <- c(details, journal_details)
    if (!nzchar(container) && nzchar(publisher)) details <- c(details, publisher)
  }

  citation <- paste0(prefix, if (nzchar(prefix)) " " else "", sentence(linked_title))
  if (length(details)) citation <- paste0(citation, " ", sentence(paste(details, collapse = ". ")))

  for (link in entry$links %||% list()) {
    label <- link$label %||% "Download manuscript or reprint PDF"
    citation <- paste0(
      citation, ' <a class="publication-pdf" href="', html_escape(link$url, attribute = TRUE),
      '" aria-label="', html_escape(label, attribute = TRUE), '">',
      '<i class="bi bi-file-earmark-pdf" aria-hidden="true"></i></a>'
    )
  }
  if (!is.null(entry$license$icon)) {
    label <- entry$license$label %||% "Publication licence"
    citation <- paste0(
      citation, ' <img class="licence-icon" src="', html_escape(entry$license$icon, attribute = TRUE),
      '" alt="', html_escape(label, attribute = TRUE), '">'
    )
  }
  citation
}

status_rank <- function(status) {
  ranks <- c("submitted" = 1L, "in review" = 2L, "in revision" = 3L, "accepted" = 4L, "in press" = 5L, "preprint" = 6L)
  unname(ranks[status] %||% 99L)
}

publication_sort_order <- function(entries, metadata) {
  status <- vapply(entries, function(x) x$status %||% "", character(1))
  in_progress <- nzchar(status)
  year <- suppressWarnings(as.integer(vapply(seq_along(entries), function(i) {
    as.character(entries[[i]]$year %||% if (is.null(metadata[[i]])) "" else date_year(metadata[[i]]))
  }, character(1))))
  year[is.na(year)] <- -Inf
  order(!in_progress, ifelse(in_progress, vapply(status, status_rank, integer(1)), -year), seq_along(entries))
}

render_publications_markdown <- function(registry, cache, path) {
  metadata <- lapply(registry$entries, publication_metadata, cache = cache)
  ord <- publication_sort_order(registry$entries, metadata)
  lines <- character()
  for (i in ord) {
    entry <- registry$entries[[i]]
    value <- if (is.null(metadata[[i]])) {
      entry$fallback_markdown
    } else {
      format_publication(metadata[[i]], entry, registry$owner %||% list(family = "Simpson", given_initial = "G"))
    }
    if (!scalar_character(value)) stop("No renderable metadata for publication '", entry$id, "'.")
    lines <- c(lines, paste0("1. ", value), "")
  }
  write_text_if_changed(paste(lines, collapse = "\n"), path)
}
