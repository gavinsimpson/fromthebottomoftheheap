# Disqus to Giscus migration

## One-time GitHub setup

1. Create the public repository
   `gavinsimpson/fromthebottomoftheheap-comments`.
2. In repository settings, enable **Discussions**.
3. Install the Giscus GitHub App for that repository from
   <https://github.com/apps/giscus>.
4. In the Discussions category settings, create an **Announcement** category
   named exactly `Blog comments` and allow reactions.
5. Confirm <https://giscus.app> reports that the repository is public, has the
   app installed, and has Discussions enabled.

Quarto post front matter already selects this repository, category, and
`pathname` mapping. The imported discussion title is therefore the canonical
path, for example `/2024/03/28/gratia-0-9-0/`.

## Obtain the Disqus export

In Disqus, open **Admin → Community → Export**, request the native export, and
download the resulting `.xml` or `.xml.gz` file. Keep it outside the repository;
`migration-private/` is available locally and is Git-ignored.

Obtain a test export for staging. Immediately before cutover, temporarily stop
new Disqus comments, request a final export, rerun the dry-run, and import that
final file. Retain the private export and Disqus account for rollback.

## Dry-run and import

Dry-run is the default and performs no GitHub writes:

```sh
python3 scripts/import-disqus.py /path/outside/git/disqus-export.xml.gz
```

Review `migration-private/disqus-dry-run.json`, especially the approved comment
count, populated-post count, exclusions, reply audit, and route map. Comments on
retired or otherwise unmapped URLs are listed in `audit.unmapped_threads` rather
than silently discarded. Test with a small export first.

After authenticating the GitHub CLI as the maintainer and reviewing the report:

```sh
gh auth login
python3 scripts/import-disqus.py /path/outside/git/disqus-export.xml.gz --apply
```

The importer:

- accepts native `.xml` and `.xml.gz` exports;
- selects non-deleted, non-spam comments and honors `isApproved` when present;
- maps the old apex or `www` URL to a canonical trailing-slash pathname;
- never copies export email addresses, IP addresses, usernames, or private
  profile data;
- converts conservative, safe HTML to GitHub Markdown;
- prefixes every comment with the original display name, UTC timestamp, and
  public author URL when present;
- preserves direct replies; deeper nesting is flattened with explicit parent
  attribution because GitHub Discussions supports one reply level; and
- updates `migration-private/disqus-ledger.json` after every GitHub write, so a
  retry cannot duplicate imported discussions or comments.

All legacy comments are submitted through the authenticated maintainer account.
The in-body attribution is deliberate; the importer never impersonates the
original authors.

The dry-run and final live export totals must match before production cutover.
Spot-check several nested discussions on a Netlify deploy preview and verify
that Giscus loads the matching discussion on its canonical post URL.
