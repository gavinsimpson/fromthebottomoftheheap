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
the committed `_site` directory. `netlify.toml` also canonicalizes only the
`www` hostname to the apex domain.

## Historical and new posts

The 103 migrated posts are historical archives. Their QMD pages were produced
from the already-rendered Markdown, so existing prose, visible code/output,
figures, and dates remain authoritative. The 37 original Rmd sources live in
`archive/rmd/` and the generated Markdown snapshots live in
`archive/generated-markdown/`; neither location is a Quarto render input.

Paired historical QMD pages retain the original block-chunk bodies as hidden R
chunks. Every one is guarded with `eval: false`, `echo: false`, `output: false`,
and `include: false`, plus an execution sentinel. Inline R expressions are not
copied because their historical evaluated text is already in the Markdown.

Create future posts from `_templates/post.qmd`. New posts may execute R and use
`freeze: auto`; historical pages intentionally do not inherit that setting.

## Comments

Post pages are configured for Giscus using pathname mapping and the separate
public repository `gavinsimpson/fromthebottomoftheheap-comments`. Repository
setup and the Disqus import procedure are documented in
[`docs/comments-migration.md`](docs/comments-migration.md).

Never commit a Disqus export or importer ledger. `migration-private/` and common
Disqus export filenames are ignored.
