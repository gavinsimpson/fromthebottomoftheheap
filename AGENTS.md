# Project instructions

## Values that change over time

Do not hardcode values, numbers, or counts that can reasonably change as the
site's content or data evolves. In implementation and tests, derive these
values from the authoritative source or check the relevant relationship or
invariant instead of relying on a snapshot of today's data.

For example, do not assert a fixed total number of publications or blog posts:
both totals will grow over time. If a total needs validation, compare it with
the current publication registry or post inventory. Fixed values are appropriate
when they express an intentional configuration or requirement, such as the
configured number of posts per page; where possible, reference that
configuration rather than duplicate its value.

## Blog posts

Use executable R chunks in blog posts unless instructed not to. Generate
displayed results and figures from those chunks.

Put package installation commands in R chunks too, but set the chunk option
`eval: false` so rendering the post does not install packages.

Always quote package names in R `library()` calls. Use `library("permute")`,
not `library(permute)`, and apply this convention to all package-loading
examples in blog posts.
