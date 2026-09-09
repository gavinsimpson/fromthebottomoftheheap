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
        threads, comments = IMPORTER.parse_export(
            ROOT / "tests" / "fixtures" / "native-export-fixture.xml", routes, unique_slugs
        )
        self.assertEqual(threads["thread-1"]["route"], "/2024/03/28/gratia-0-9-0/")
        self.assertEqual([comment["id"] for comment in comments], ["comment-1", "comment-2", "comment-3"])
        serialized = repr(comments)
        self.assertNotIn("private@example.test", serialized)
        self.assertNotIn("192.0.2.1", serialized)
        self.assertEqual(comments[1]["parent_id"], "comment-1")
        self.assertEqual(comments[2]["parent_id"], "comment-2")

    def test_html_is_converted_without_active_content(self):
        markdown = IMPORTER.to_markdown('<p><strong>Safe</strong></p><script>bad()</script>')
        self.assertEqual(markdown, "**Safe**")


if __name__ == "__main__":
    unittest.main()
