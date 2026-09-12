#!/usr/bin/env Rscript

options(warn = 2)
if (!requireNamespace("renv", quietly = TRUE)) {
  stop("Install renv once with install.packages('renv'), then rerun this command.")
}
renv::restore(prompt = FALSE)

quarto_version <- tryCatch(system2("quarto", "--version", stdout = TRUE), error = function(error) character())
if (!identical(quarto_version[[1L]], "1.10.18")) {
  stop("This migration is pinned to Quarto 1.10.18; found ", paste(quarto_version, collapse = " "))
}

commands <- list(
  c("Rscript", "scripts/generate-archives.R"),
  c("quarto", "render"),
  c("Rscript", "scripts/compatibility-files.R"),
  c("Rscript", "scripts/validate-site.R"),
  c("Rscript", "tests/test-publications.R"),
  c("python3", "tests/test-import-disqus.py")
)

for (command in commands) {
  status <- system2(command[[1L]], command[-1L])
  if (!identical(status, 0L)) stop("Command failed: ", paste(command, collapse = " "))
}
