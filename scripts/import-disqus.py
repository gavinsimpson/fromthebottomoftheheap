#!/usr/bin/env python3
"""Import approved Disqus comments into GitHub Discussions for Giscus.

Dry-run is the default. Pass --apply only after reviewing the JSON report.
The export and idempotency ledger must remain outside version control.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import html
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import urlsplit
import xml.etree.ElementTree as ET

DSQ_ID = "{http://disqus.com/disqus-internals}id"
SITE_HOSTS = {"fromthebottomoftheheap.net", "www.fromthebottomoftheheap.net"}


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def child_of(node: ET.Element, name: str) -> ET.Element | None:
    return next((child for child in node if local_name(child.tag) == name), None)


def text_of(node: ET.Element, name: str, default: str = "") -> str:
    child = child_of(node, name)
    return default if child is None or child.text is None else child.text.strip()


def truth(value: str, default: bool = False) -> bool:
    if not value:
        return default
    return value.lower() in {"true", "1", "yes"}


def canonical_path(url: str) -> str | None:
    try:
        parsed = urlsplit(url)
    except ValueError:
        return None
    if parsed.hostname and parsed.hostname.lower() not in SITE_HOSTS:
        return None
    path = re.sub(r"/{2,}", "/", parsed.path or "/")
    if path.endswith("/index.html"):
        path = path[: -len("index.html")]
    elif path.endswith(".html"):
        path = path[: -len(".html")]
    if path != "/" and not path.endswith("/"):
        path += "/"
    return path


def load_post_routes(path: Path) -> tuple[set[str], dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        routes = {row["url"] for row in csv.DictReader(handle)}
    by_slug: dict[str, list[str]] = {}
    for route in routes:
        slug = route.rstrip("/").rsplit("/", 1)[-1]
        by_slug.setdefault(slug, []).append(route)
    unique_slugs = {slug: values[0] for slug, values in by_slug.items() if len(values) == 1}
    return routes, unique_slugs


def post_path(url: str, routes: set[str], unique_slugs: dict[str, str]) -> str | None:
    route = canonical_path(url)
    if route in routes:
        return route
    if route:
        return unique_slugs.get(route.rstrip("/").rsplit("/", 1)[-1])
    return None


class SafeMarkdown(HTMLParser):
    """Conservative Disqus HTML to GitHub-flavoured Markdown conversion."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.skip = 0
        self.hrefs: list[str] = []
        self.list_depth = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in {"script", "style", "iframe", "object"}:
            self.skip += 1
            return
        if self.skip:
            return
        attrs_dict = dict(attrs)
        if tag in {"p", "div"}:
            self.parts.append("\n\n")
        elif tag == "br":
            self.parts.append("  \n")
        elif tag in {"strong", "b"}:
            self.parts.append("**")
        elif tag in {"em", "i"}:
            self.parts.append("_")
        elif tag == "code":
            self.parts.append("`")
        elif tag == "pre":
            self.parts.append("\n```text\n")
        elif tag == "blockquote":
            self.parts.append("\n> ")
        elif tag in {"ul", "ol"}:
            self.list_depth += 1
            self.parts.append("\n")
        elif tag == "li":
            self.parts.append("\n" + "  " * max(self.list_depth - 1, 0) + "- ")
        elif tag == "a":
            href = attrs_dict.get("href") or ""
            safe = href if href.startswith(("https://", "http://", "mailto:")) else ""
            self.hrefs.append(safe)
            self.parts.append("[")

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "iframe", "object"}:
            self.skip = max(0, self.skip - 1)
            return
        if self.skip:
            return
        if tag in {"strong", "b"}:
            self.parts.append("**")
        elif tag in {"em", "i"}:
            self.parts.append("_")
        elif tag == "code":
            self.parts.append("`")
        elif tag == "pre":
            self.parts.append("\n```\n")
        elif tag == "blockquote":
            self.parts.append("\n")
        elif tag in {"ul", "ol"}:
            self.list_depth = max(0, self.list_depth - 1)
            self.parts.append("\n")
        elif tag == "a":
            href = self.hrefs.pop() if self.hrefs else ""
            self.parts.append(f"]({href})" if href else "]")
        elif tag in {"p", "div"}:
            self.parts.append("\n\n")

    def handle_data(self, data: str) -> None:
        if not self.skip:
            self.parts.append(data)

    def markdown(self) -> str:
        value = "".join(self.parts).replace("\r", "")
        value = re.sub(r"[ \t]+\n", "\n", value)
        value = re.sub(r"\n{3,}", "\n\n", value)
        return value.strip()


def to_markdown(value: str) -> str:
    parser = SafeMarkdown()
    parser.feed(html.unescape(value))
    return parser.markdown()


def open_export(path: Path):
    return gzip.open(path, "rb") if path.suffix == ".gz" else path.open("rb")


def parse_export(path: Path, routes: set[str], unique_slugs: dict[str, str]) -> tuple[dict[str, dict], list[dict]]:
    with open_export(path) as handle:
        root = ET.parse(handle).getroot()

    threads: dict[str, dict] = {}
    for node in (child for child in root if local_name(child.tag) == "thread"):
        identifier = node.attrib.get(DSQ_ID, "")
        route = post_path(text_of(node, "link"), routes, unique_slugs)
        if identifier and route and not truth(text_of(node, "isDeleted")):
            threads[identifier] = {
                "route": route,
                "title": text_of(node, "title", route),
                "link": text_of(node, "link"),
            }

    comments: list[dict] = []
    for order, node in enumerate(child for child in root if local_name(child.tag) == "post"):
        identifier = node.attrib.get(DSQ_ID, "")
        thread = child_of(node, "thread")
        thread_id = "" if thread is None else thread.attrib.get(DSQ_ID, "")
        if not identifier or thread_id not in threads:
            continue
        if truth(text_of(node, "isDeleted")) or truth(text_of(node, "isSpam")):
            continue
        approved_text = text_of(node, "isApproved")
        if approved_text and not truth(approved_text):
            continue
        author = child_of(node, "author")
        parent = child_of(node, "parent")
        comments.append(
            {
                "id": identifier,
                "thread_id": thread_id,
                "parent_id": "" if parent is None else parent.attrib.get(DSQ_ID, ""),
                "created_at": text_of(node, "createdAt"),
                "name": "Anonymous" if author is None else text_of(author, "name", "Anonymous"),
                "url": "" if author is None else text_of(author, "url"),
                "message": to_markdown(text_of(node, "message")),
                "order": order,
            }
        )
    return threads, comments


def gh_graphql(query: str, variables: dict) -> dict:
    command = ["gh", "api", "graphql", "-f", f"query={query}"]
    for key, value in variables.items():
        command.extend(["-F", f"{key}={value}"])
    process = subprocess.run(command, text=True, capture_output=True)
    if process.returncode:
        raise RuntimeError(process.stderr.strip() or process.stdout.strip())
    return json.loads(process.stdout)


def repo_info(owner: str, name: str, category: str) -> tuple[str, str]:
    result = gh_graphql(
        "query($owner:String!,$name:String!){repository(owner:$owner,name:$name){id discussionCategories(first:100){nodes{id name}}}}",
        {"owner": owner, "name": name},
    )["data"]["repository"]
    categories = {item["name"]: item["id"] for item in result["discussionCategories"]["nodes"]}
    if category not in categories:
        raise RuntimeError(f"Discussion category {category!r} does not exist")
    return result["id"], categories[category]


def create_discussion(repo_id: str, category_id: str, route: str, source_url: str) -> str:
    body = f"Legacy blog discussion for [{route}]({source_url}). Comments below were migrated from Disqus."
    result = gh_graphql(
        "mutation($repositoryId:ID!,$categoryId:ID!,$title:String!,$body:String!){createDiscussion(input:{repositoryId:$repositoryId,categoryId:$categoryId,title:$title,body:$body}){discussion{id}}}",
        {"repositoryId": repo_id, "categoryId": category_id, "title": route, "body": body},
    )
    return result["data"]["createDiscussion"]["discussion"]["id"]


def add_comment(discussion_id: str, body: str, reply_to: str = "") -> str:
    if reply_to:
        query = "mutation($discussionId:ID!,$body:String!,$replyToId:ID!){addDiscussionComment(input:{discussionId:$discussionId,body:$body,replyToId:$replyToId}){comment{id}}}"
        variables = {"discussionId": discussion_id, "body": body, "replyToId": reply_to}
    else:
        query = "mutation($discussionId:ID!,$body:String!){addDiscussionComment(input:{discussionId:$discussionId,body:$body}){comment{id}}}"
        variables = {"discussionId": discussion_id, "body": body}
    result = gh_graphql(query, variables)
    return result["data"]["addDiscussionComment"]["comment"]["id"]


def attributed_body(comment: dict, parent: dict | None = None) -> str:
    author_url = comment["url"] if comment["url"].startswith(("https://", "http://")) else ""
    author = f"[{comment['name']}]({author_url})" if author_url else comment["name"]
    prefix = f"**Legacy comment by {author} — {comment['created_at']} UTC**"
    if parent is not None:
        prefix += f"  \n_Replying to {parent['name']} (legacy Disqus comment {parent['id']})._"
    return f"{prefix}\n\n{comment['message']}".strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("export", type=Path, help="Disqus .xml or .xml.gz export (kept outside Git)")
    parser.add_argument("--repo", default="gavinsimpson/fromthebottomoftheheap-comments")
    parser.add_argument("--category", default="Blog comments")
    parser.add_argument("--manifest", type=Path, default=Path("migration/post-manifest.csv"))
    parser.add_argument("--ledger", type=Path, default=Path("migration-private/disqus-ledger.json"))
    parser.add_argument("--report", type=Path, default=Path("migration-private/disqus-dry-run.json"))
    parser.add_argument("--apply", action="store_true", help="Create discussions and comments")
    args = parser.parse_args()

    if not args.export.exists() or args.export.suffix not in {".xml", ".gz"}:
        parser.error("export must be an existing .xml or .xml.gz file")
    if not args.manifest.exists():
        parser.error("post manifest does not exist")
    routes, unique_slugs = load_post_routes(args.manifest)
    threads, comments = parse_export(args.export, routes, unique_slugs)
    populated = sorted({comment["thread_id"] for comment in comments})
    report = {
        "mode": "apply" if args.apply else "dry-run",
        "approved_comments": len(comments),
        "populated_posts": len(populated),
        "routes": {threads[key]["route"]: sum(c["thread_id"] == key for c in comments) for key in populated},
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    if not args.apply:
        return 0

    owner, name = args.repo.split("/", 1)
    repo_id, category_id = repo_info(owner, name, args.category)
    if args.ledger.exists():
        ledger = json.loads(args.ledger.read_text(encoding="utf-8"))
    else:
        ledger = {"discussions": {}, "comments": {}}
    comments_by_id = {comment["id"]: comment for comment in comments}

    for thread_id in populated:
        thread = threads[thread_id]
        discussion_id = ledger["discussions"].get(thread_id)
        if not discussion_id:
            discussion_id = create_discussion(repo_id, category_id, thread["route"], thread["link"])
            ledger["discussions"][thread_id] = discussion_id
            args.ledger.parent.mkdir(parents=True, exist_ok=True)
            args.ledger.write_text(json.dumps(ledger, indent=2, sort_keys=True) + "\n", encoding="utf-8")

        thread_comments = sorted((c for c in comments if c["thread_id"] == thread_id), key=lambda c: (c["created_at"], c["order"]))
        for comment in thread_comments:
            if comment["id"] in ledger["comments"]:
                continue
            parent = comments_by_id.get(comment["parent_id"])
            reply_to = ""
            attributed_parent = None
            if parent is not None:
                parent_gh = ledger["comments"].get(parent["id"], "")
                grandparent = comments_by_id.get(parent["parent_id"])
                if parent_gh and grandparent is None:
                    reply_to = parent_gh
                else:
                    attributed_parent = parent
            github_id = add_comment(discussion_id, attributed_body(comment, attributed_parent), reply_to)
            ledger["comments"][comment["id"]] = github_id
            args.ledger.write_text(json.dumps(ledger, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ET.ParseError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
