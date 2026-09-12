# Style parity audit

The migration audit compared the final Jekyll and Quarto HTML for the 400
paths present in both rendered sites. It inventoried the semantic elements and
legacy component classes that occur on those pages, then traced their active
rules through `assets/css/bootstrap.css`, `assets/css/ftboth.css`, and the
compiled Quarto Bootstrap bundle.

The scan covered 5,977 legacy paragraphs, 287 `h2` headings, 204 `h3`
headings, 1,040 preformatted blocks, 3,811 code elements, 12 blockquotes, 88
keyboard-key elements, and the site-wide navigation, post metadata, listings,
tables, figures, sidebars, labels, and footer. Differences caused solely by the
new semantic markup (for example, Quarto tables replacing the old blog
definition list) were treated as structural rather than visual differences.

## Legacy design values retained

| Area | Jekyll value | Quarto implementation |
|---|---|---|
| Body type | Open Sans, 14px/20px, `#333333` | Bootstrap root/body variables |
| Links | `#f43d00`, no underline; `#ff7142` and underline on hover | Bootstrap link variables plus hover rule |
| Headings | Open Sans Condensed, weight 300, orange | Bootstrap heading variables plus a late rule that overrides Quarto's weight-600 selectors |
| Heading scale | 38.5, 31.5, 24.5, 17.5, 14, and 11.9px | Explicit `h1`–`h6` scale |
| Heading rhythm | 40px for `h1`–`h3`; 20px for `h4`–`h6`; 10px vertical margins | Explicit heading rules |
| Paragraphs and lists | 10px bottom rhythm; list text on a 20px line | Content rules that do not alter the Bootstrap navbar |
| Inline/code blocks | 12px inline; 13px/20px blocks; 9.5px block padding; 8px radius | Shared source/output rules with the Monokai palette retained |
| Figures and captions | 3em figure spacing; 17.5px/20px orange condensed captions | Figure and caption rules |
| Tables | 3em spacing, 4px × 5px cells, 20px lines, striped rows, 4px radius | Table rules applied after Quarto's defaults |
| Blockquotes | Right orange rule, orange 14px/20px text | Legacy blockquote treatment |
| Keyboard keys | 11px inset key-cap treatment | Ported `kbd` rule |
| Slide labels | Legacy warning, success, info, and inverse label colours and dimensions | Bootstrap-5-compatible `.label` rules |
| Social/blogroll | 12px social links, 10px blogroll, 17.5px headings | Shared sidebar rules |
| Desktop post alignment | Main column begins at the same left edge as home-page post excerpts | Post-only grid override; right sidebar remains in Quarto's margin column |
| Footer | 150px minimum height, 40px top margin, 20px padding, white text on `#272822` | Quarto footer rules |

Bootstrap 2 layout selectors, Glyphicons, and obsolete JavaScript behaviours
are deliberately not restored. The wider home listing and the responsive
placement of Social and Blogroll follow the approved Quarto layout.
