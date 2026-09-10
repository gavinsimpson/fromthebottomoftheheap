#!/usr/bin/env python3

import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("import_disqus", ROOT / "scripts" / "import-disqus.py")
IMPORTER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(IMPORTER)


class ImportDisqusTests(unittest.TestCase):
    def test_native_namespaces_filters_and_manifest_aliases(self):
        routes, unique_slugs = IMPORTER.load_post_routes(ROOT / "migration" / "post-manifest.csv")
        threads, comments, audit = IMPORTER.parse_export(
            ROOT / "tests" / "fixtures" / "native-export-fixture.xml", routes, unique_slugs
        )
        self.assertEqual(threads["thread-1"]["route"], "/2024/03/28/gratia-0-9-0/")
        self.assertEqual([comment["id"] for comment in comments], ["comment-1", "comment-2", "comment-3"])
        serialized = repr(comments)
        self.assertNotIn("private@example.test", serialized)
        self.assertNotIn("192.0.2.1", serialized)
        self.assertEqual(comments[1]["parent_id"], "comment-1")
        self.assertEqual(comments[2]["parent_id"], "comment-2")
        self.assertEqual(audit["raw_comments"], 6)
        self.assertEqual(audit["skipped_comments"]["deleted"], 1)
        self.assertEqual(audit["skipped_comments"]["spam"], 1)

    def test_html_is_converted_without_active_content(self):
        markdown = IMPORTER.to_markdown('<p><strong>Safe</strong></p><script>bad()</script>')
        self.assertEqual(markdown, "**Safe**")

    def test_unavailable_parent_is_explicitly_attributed(self):
        body = IMPORTER.attributed_body(
            {
                "name": "A reader",
                "url": "",
                "created_at": "2020-01-01T00:00:00.000000+0000",
                "message": "A surviving reply.",
            },
            unavailable_parent_id="deleted-parent",
        )
        self.assertIn("Replying to unavailable legacy Disqus comment deleted-parent", body)


if __name__ == "__main__":
    unittest.main()
