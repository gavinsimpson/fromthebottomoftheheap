#!/usr/bin/env Rscript

source("scripts/publications.R")

render_all <- identical(Sys.getenv("QUARTO_PROJECT_RENDER_ALL"), "1")
input_files <- strsplit(Sys.getenv("QUARTO_PROJECT_INPUT_FILES"), "\n", fixed = TRUE)[[1L]]
input_files <- gsub("\\\\", "/", input_files)
publication_requested <- any(endsWith(input_files, "publications/index.qmd"))
if (!render_all && length(input_files) && all(nzchar(input_files)) && !publication_requested) quit(save = "no")

paths <- publication_paths()
registry <- read_publication_registry(paths$registry)
validate_publication_registry(registry)
result <- refresh_publication_cache(registry, paths$cache, refresh_all = FALSE)
invisible(render_publications_markdown(registry, result$cache, paths$generated))
