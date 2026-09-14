# From the bottom of the heap

Source and rendered output for <https://fromthebottomoftheheap.net>.

The site is a Quarto website pinned to **Quarto 1.10.18**, which supplies
**Bootstrap 5.3.1**. Bootstrap is not vendored separately: upgrading Bootstrap
means deliberately upgrading Quarto and rerunning the validation suite.

## Render locally

Install Quarto 1.10.18 and R, then install `renv` once if necessary. The single
supported build command is:

```sh
Rscript scripts/render-site.R
```

That command restores/checks the small locked R environment, regenerates tag
and category pages, renders Quarto, creates `/feed.xml` and `/feed-R.xml`, and
validates routes, assets, Bootstrap, Giscus, links, and historical execution
safeguards. Run it twice before committing a release; the second run must not
create unexplained tracked changes.

Source and `_site/` are committed. Netlify runs no build command and publishes
the committed `_site` directory. `netlify.toml` canonicalizes the `www`
hostname to the apex domain and redirects the recovered post's legacy `/228/`
path to its descriptive canonical URL.

## Historical and new posts

The 104 migrated posts are historical archives. Their QMD pages were produced
from the already-rendered Markdown, so existing prose, visible code/output,
figures, and dates remain authoritative. The 37 original Rmd sources live in
`archive/rmd/` and the generated Markdown snapshots live in
`archive/generated-markdown/`; neither location is a Quarto render input.

Paired historical QMD pages retain the original block-chunk bodies as hidden R
chunks. Every one is guarded with `eval: false`, `echo: false`, `output: false`,
and `include: false`, plus an execution sentinel. Inline R expressions are not
copied because their historical evaluated text is already in the Markdown.

Create each future post at `YYYY/MM/DD/slug/index.qmd`, where the directories
are the publication date and `slug` is a short, lowercase, hyphen-separated
name. This path becomes the permanent public URL and the Giscus discussion key,
so do not change it after publication without also adding a redirect and
planning how to preserve the associated discussion.

For example, to start a post dated 14 September 2026:

```sh
mkdir -p 2026/09/14/example-post
cp _templates/post.qmd 2026/09/14/example-post/index.qmd
```

Edit the copied front matter before writing:

- replace `title`, `subtitle`, and `date` (prefer an explicit ISO date over
  `today` for a committed post);
- keep `category` and `categories` consistent, and add any `tags`;
- optionally add `description` and an `image` for listings and social cards;
- leave the Giscus configuration and the four-level-deep social-blogroll
  include unchanged.

Put post images in `assets/img/posts/`, preferably with the post slug in each
filename, and refer to them with root-relative paths such as
`/assets/img/posts/example-post-result.png`. Other downloadable files belong in
an appropriate directory below `assets/`.

New posts may execute R and use `freeze: auto`; historical pages intentionally
do not inherit that setting. `quarto preview` is convenient while writing, but
it is not the release check. Before committing, run the supported build command
above twice. Review `git status` and the rendered post in `_site/`; commit the
post source, its assets, regenerated tag/category sources, `_site/`, and any
`_freeze/` files created for executable code. The second build should not add
further unexplained changes.

## Publications

Add and update papers in `publications/publications.yml`; do not edit the
generated publication list. DOI, preprint, submission-to-publication, cache,
and validation workflows are documented in
[`publications/README.md`](publications/README.md).

## Comments

Post pages are configured for Giscus using pathname mapping and the separate
public repository `gavinsimpson/fromthebottomoftheheap-comments`. Repository
setup and the Disqus import procedure are documented in
[`docs/comments-migration.md`](docs/comments-migration.md).

Never commit a Disqus export or importer ledger. `migration-private/` and common
Disqus export filenames are ignored.
