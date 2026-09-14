#!/usr/bin/env python3
"""Check internal links and embedded resources in the rendered Quarto site."""

from __future__ import annotations

import argparse
from html.parser import HTMLParser
from pathlib import Path
import posixpath
from urllib.parse import unquote, urlsplit


class References(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.values: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        for attribute in ("href", "src", "poster"):
            value = values.get(attribute)
            if value:
                self.values.append(value)
        if values.get("srcset"):
            self.values.extend(item.strip().split()[0] for item in values["srcset"].split(","))


def resolves(site: Path, page: Path, value: str) -> bool:
    if value.startswith(("#", "mailto:", "tel:", "javascript:", "data:", "//")):
        return True
    parsed = urlsplit(value)
    if parsed.scheme or parsed.netloc:
        return True
    path = unquote(parsed.path)
    if not path:
        return True
    candidate = site / path.lstrip("/") if path.startswith("/") else page.parent / path
    candidate = Path(posixpath.normpath(candidate.as_posix()))
    if path.endswith("/"):
        candidate = candidate / "index.html"
    elif candidate.is_dir():
        candidate = candidate / "index.html"
    return candidate.exists()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("site", nargs="?", type=Path, default=Path("_site"))
    args = parser.parse_args()
    site = args.site.resolve()
    failures: list[str] = []
    for page in sorted(site.rglob("*.html")):
        if any(part.endswith("_files") for part in page.relative_to(site).parts):
            continue
        references = References()
        references.feed(page.read_text(encoding="utf-8", errors="replace"))
        for value in references.values:
            if not resolves(site, page, value):
                failures.append(f"{page.relative_to(site)}: {value}")
    if failures:
        print("Broken internal references:")
        print("\n".join(failures[:100]))
        if len(failures) > 100:
            print(f"... and {len(failures) - 100} more")
        return 1
    print(f"Validated internal links and resources across {sum(1 for _ in site.rglob('*.html'))} HTML pages.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
