# Maintaining the publications page

`publications.yml` is the authoritative list. The generated page must not be
edited by hand.

## Choose the command for the task

Updating publication data and rendering the website are separate operations.
You do **not** need to render the site just to update the DOI cache.

### Prepare routine publication changes without rendering the site

After editing `publications.yml`, run:

```sh
Rscript scripts/prepare-publications.R
```

This validates the registry, fetches metadata only for a new or changed DOI,
updates `doi-cache.json` when necessary, and regenerates the ignored
`_generated-publications.md` intermediate. It does not invoke Quarto or change
anything in `_site/`. For a status-only change to an already-cached DOI, it
normally makes no cache change but still regenerates the intermediate.

### Force-refresh all DOI metadata without rendering the site

Run:

```sh
Rscript scripts/refresh-publications.R
```

This contacts the DOI services for every DOI, refreshes `doi-cache.json`, and
updates `doi-suggestions.yml`. It also regenerates the ignored intermediate,
but it does not render the website. This is primarily a maintenance command;
the scheduled weekly workflow already runs it automatically.

### Render only the publications page

To see prepared changes in the committed website output without rebuilding
every page, run:

```sh
Rscript scripts/prepare-publications.R
quarto render publications/index.qmd
Rscript tests/test-publications.R
```

Review `_site/publications/index.html` and the files reported by `git status`.
This targeted workflow is normally sufficient while editing and reviewing
publication changes.

### Run the full release verification

Run `Rscript scripts/render-site.R` only when you want the complete release
build and validation suite. It deliberately regenerates and checks the entire
site. Following the repository release policy, run it twice before committing
a deployable release; the second run should produce no unexplained changes.
This full render is a release check, not a prerequisite for updating the
publications cache.

## Add a publication with a DOI

Add an entry anywhere under `entries`:

```yaml
- id: simpson-2026-short-description
  doi: 10.xxxx/example
```

The `id` is permanent and must be unique. The preparation command fetches
metadata when the ID is new or its DOI differs from the cached DOI; later
preparations are fully local. Commit both the registry and updated cache.

Site-specific links and licence information stay in the registry:

```yaml
- id: simpson-2026-short-description
  doi: 10.xxxx/example
  links:
  - kind: pdf
    url: /assets/reprints/example.pdf
    label: Download accepted manuscript PDF
  license:
    type: cc-by
    label: Creative Commons Attribution
```

Use `type: cc-by` for a CC BY licence or `type: cc-by-nc` for CC BY-NC. The
site renders the corresponding Font Awesome Creative Commons symbols inline;
there is no image file to add or maintain.

Use `status: preprint`, `submitted`, `in review`, `in revision`, `accepted`, or
`in press` only while that label should replace the publication year. Remove
the status after switching the entry to its version-of-record DOI.

For a preprint that should be monitored for an explicitly registered published
version, add `check_for_version_of_record: true`. The weekly refresh records any
Crossref or DataCite relationship in `doi-suggestions.yml` for review; it never
silently replaces the DOI.

## Add a publication without a DOI

Use `fallback_markdown` for the formatted citation and optionally add `year`,
`status`, `links`, and `license`. This supports older chapters and manuscripts
for which reliable structured metadata does not exist.

## Correct publisher metadata

Add only the corrected CSL fields under `overrides`. Overrides always win over
the cached DOI response:

```yaml
  overrides:
    title: Corrected title
    issue: '2'
    page: 10-25
```

Run `Rscript scripts/refresh-publications.R` to refresh every DOI explicitly.
The scheduled workflow does this weekly and opens or updates one reviewable PR
when the normalized cache changes. It does not use ORCID.

## Typical manuscript workflow

### Add a submitted paper without a DOI

Use a permanent ID, a temporary status, and a complete formatted citation:

```yaml
- id: simpson-2026-lake-trends
  status: submitted
  fallback_markdown: >-
    Simpson, G.L. & Example, A. (submitted) Trends in example lakes.
    *Example Journal*.
```

Change `status` as the manuscript progresses through `in review`, `in
revision`, `accepted`, or `in press`. Because a fallback citation is rendered
verbatim, also change its parenthesized status text at every transition; the
separate `status` field controls ordering but does not rewrite
`fallback_markdown`.

### Add and monitor a preprint

When the preprint has its own DOI, use that DOI and opt in to version-of-record
checks:

```yaml
- id: simpson-2026-lake-trends
  doi: 10.1101/2026.01.23.123456
  status: preprint
  check_for_version_of_record: true
  links:
  - kind: pdf
    url: https://example.org/lake-trends-preprint.pdf
    label: Download preprint PDF
```

The weekly refresh may add a candidate journal DOI to
`doi-suggestions.yml`. Treat that file as a suggestion for review, not as an
automatic change to the public citation.

### Change a submission or preprint to the published version

Keep the existing permanent `id`, replace any preprint DOI with the
version-of-record DOI, and remove both the temporary `status` and
`check_for_version_of_record`. If the entry used `fallback_markdown`, remove it
once the publisher DOI supplies reliable metadata. Retain or update useful PDF
and licence links. For example, the preprint above becomes:

```yaml
- id: simpson-2026-lake-trends
  doi: 10.1234/example.2026.12345
  links:
  - kind: pdf
    url: /assets/reprints/simpson-et-al-lake-trends-2026.pdf
    label: Download accepted manuscript PDF
```

Prepare the changed record without rendering the site:

```sh
Rscript scripts/prepare-publications.R
```

This fetches and caches metadata for a new or changed DOI. Render the targeted
publications page when you want to review the website output, and use the full
release command only when preparing to deploy, as described above. Commit
`publications/publications.yml`, `publications/doi-cache.json`, the rendered
`_site/` changes when publishing them, and the manuscript PDF if it is hosted
locally. Do not commit `publications/_generated-publications.md`; it is an
ignored build intermediate.
