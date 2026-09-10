# Maintaining the publications page

`publications.yml` is the authoritative list. The generated page must not be
edited by hand.

## Add a publication with a DOI

Add an entry anywhere under `entries`:

```yaml
- id: simpson-2026-short-description
  doi: 10.xxxx/example
```

The `id` is permanent and must be unique. `quarto render` fetches metadata only
when that ID and DOI are absent from `doi-cache.json`; later renders are fully
local. Commit both the registry and updated cache.

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
