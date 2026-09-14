# Maintaining the publications page

`publications.yml` is the authoritative list. The generated page must not be
edited by hand.

## Add a publication with a DOI

Add an entry anywhere under `entries`:

```yaml
- id: simpson-2026-short-description
  doi: 10.xxxx/example
```

The `id` is permanent and must be unique. The supported site build fetches
metadata only when that ID and DOI are absent from `doi-cache.json`; later
renders are fully local. Commit both the registry and updated cache.

Site-specific links and licence information stay in the registry:

```yaml
- id: simpson-2026-short-description
  doi: 10.xxxx/example
  links:
  - kind: pdf
    url: /assets/reprints/example.pdf
    label: Download accepted manuscript PDF
  license:
    icon: /assets/img/cc-by.png
    label: Creative Commons Attribution
```

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

Then run:

```sh
Rscript scripts/render-site.R
Rscript scripts/render-site.R
```

The first run fetches and caches metadata for a new or changed DOI, rebuilds
the publications page and site, and runs all validation. The second run checks
that the committed result is stable. Review the citation in
`_site/publications/index.html`, then commit `publications/publications.yml`,
`publications/doi-cache.json`, `_site/`, any changed generated site sources,
and the manuscript PDF if it is hosted locally. Do not commit
`publications/_generated-publications.md`; it is an ignored build intermediate.
