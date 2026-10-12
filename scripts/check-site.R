#!/usr/bin/env Rscript

# Validate the already-rendered site. This command never renders or restores
# packages; run renv::restore() explicitly after changing the environment.
options(warn = 2)
# The parent R session has already performed renv's startup consistency check.
# Keep each test's mocks and globals isolated without repeating that check.
Sys.setenv(RENV_CONFIG_SYNCHRONIZED_CHECK = "false")
for (path in c(
  "tests/test-posts.R",
  "tests/test-feeds.R",
  "tests/test-build.R",
  "tests/test-publications.R",
  "scripts/validate-site.R"
)) {
  message("Checking ", path)
  status <- system2("Rscript", shQuote(path))
  if (!identical(status, 0L)) stop("Check failed: ", path)
}
status <- system2("python3", "tests/test-import-disqus.py")
if (!identical(status, 0L)) stop("Disqus importer tests failed")
message("All site checks passed.")
