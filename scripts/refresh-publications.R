#!/usr/bin/env Rscript

source("scripts/publications.R")

paths <- publication_paths()
registry <- read_publication_registry(paths$registry)
validate_publication_registry(registry)
result <- refresh_publication_cache(registry, paths$cache, refresh_all = TRUE)
relationships_changed <- refresh_version_of_record_suggestions(registry, paths$suggestions)
invisible(render_publications_markdown(registry, result$cache, paths$generated))

message(if (result$changed) "Publication metadata cache updated." else "Publication metadata is unchanged.")
if (relationships_changed) message("Version-of-record suggestions updated.")
