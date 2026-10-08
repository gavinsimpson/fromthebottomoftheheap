#!/usr/bin/env Rscript

project <- normalizePath(getwd())
source(file.path(project, "scripts", "posts.R"))
assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}

# Exercise growth and draft transitions in an isolated site, independent of
# today's number of posts or the historical migration manifest.
fixture <- tempfile("post-inventory-")
dir.create(fixture)
for (directory in c("scripts", "blog", "feed-R")) dir.create(file.path(fixture, directory))
invisible(file.copy(file.path(project, "scripts", "posts.R"), file.path(fixture, "scripts", "posts.R")))
write_post <- function(path, fields) {
  destination <- file.path(fixture, path)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  writeLines(c("---", fields, "---", "", "Fixture post."), destination)
}
existing <- "2025/01/01/existing/index.qmd"
new <- "2026/10/08/new/index.qmd"
draft <- "2027/01/01/draft/index.qmd"
write_post(existing, c("title: Existing", "category: R", "categories: [R]", "tags: [shared]"))
write_post(new, c("title: New", "categories: [Science, R]", "tags: [shared, New tag]"))
write_post(draft, c("title: Draft", "draft: true", "category: Science", "tags: [Draft tag]"))
write_post("_site/2028/01/01/output/index.qmd", "title: Output copy")
write_post("_templates/index.qmd", "title: Template")

posts <- discover_posts(fixture)
assert(setequal(posts$qmd, c(existing, new)), "Discovery must include new posts and exclude drafts, templates, and output copies.")
assert(setequal(r_post_paths(posts), c(existing, new)), "R eligibility must include singular and plural categories without duplicates.")
assert(setequal(discover_posts(fixture, include_drafts = TRUE)$qmd, c(existing, new, draft)), "Explicit draft discovery must retain drafts.")

original_directory <- getwd()
setwd(fixture)
generate <- function() source(file.path(project, "scripts", "generate-archives.R"), local = new.env())
listing_sources <- function(path, prefix) {
  paths <- unlist(read_qmd_metadata(path)$listing$contents, use.names = FALSE)
  assert(all(startsWith(paths, prefix)), paste("Unexpected listing path prefix in", path))
  substring(paths, nchar(prefix) + 1L)
}
generate()
assert(setequal(listing_sources("index.qmd", ""), posts$qmd), "Home must discover the current published inventory.")
assert(setequal(listing_sources("blog/2026/index.qmd", "../../"), new), "A new year must receive an archive automatically.")
assert(setequal(listing_sources("category/science/index.qmd", "../../"), new), "Plural categories must receive archives.")
assert(setequal(listing_sources("category/r/index.qmd", "../../"), c(existing, new)), "Category aliases must not duplicate a post.")
assert(setequal(listing_sources("tag/shared/index.qmd", "../../"), posts$qmd), "Shared tag archives must include new posts.")
assert(file.exists("tag/new-tag/index.qmd") && !file.exists("tag/draft-tag/index.qmd") && !file.exists("blog/2027/index.qmd"), "Draft-only tags and years must be excluded.")

write_post(new, c("title: New", "draft: true", "categories: [Science, R]", "tags: [shared, New tag]"))
generate()
assert(identical(listing_sources("index.qmd", ""), existing), "Returning a post to draft must remove it from listings.")
assert(!any(file.exists(c("blog/2026/index.qmd", "category/science/index.qmd", "tag/new-tag/index.qmd"))), "Obsolete generated archives must be removed.")
write_post(new, c("title: New", "draft: false", "category: Science", "tags: [R]"))
generate()
assert(setequal(listing_sources("index.qmd", ""), posts$qmd), "Publishing again must restore the post and its year.")
assert(identical(listing_sources("feed-R/index.qmd", "../"), existing), "An R tag alone must not qualify for the R feed.")
generated_files <- list.files(fixture, pattern = "index\\.qmd$", recursive = TRUE, full.names = TRUE)
before <- tools::md5sum(generated_files)
generate()
assert(identical(before, tools::md5sum(generated_files)), "Regenerating unchanged archives must be deterministic.")
setwd(original_directory)
unlink(fixture, recursive = TRUE)
cat("Post discovery and archive tests passed.\n")
