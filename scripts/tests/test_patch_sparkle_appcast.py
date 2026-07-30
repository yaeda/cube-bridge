from __future__ import annotations

import argparse
import unittest
import xml.etree.ElementTree as ET

from scripts.patch_sparkle_appcast import (
    SPARKLE_NS,
    find_update_item,
    patch_item,
)


XML_NS = "http://www.w3.org/XML/1998/namespace"
REPOSITORY = "yaeda/cube-bridge"
VERSION = "1.2.3"


class PatchSparkleAppcastTests(unittest.TestCase):
    def test_finds_the_item_matching_the_requested_sparkle_version(self) -> None:
        root = ET.fromstring(
            f"""
            <rss xmlns:sparkle="{SPARKLE_NS}">
              <channel>
                <item><sparkle:version>1.2.2</sparkle:version></item>
                <item><sparkle:version>{VERSION}</sparkle:version></item>
              </channel>
            </rss>
            """
        )

        item = find_update_item(root, VERSION)

        self.assertEqual(
            item.findtext(f"{{{SPARKLE_NS}}}version"),
            VERSION,
        )
        with self.assertRaisesRegex(SystemExit, "no item for version 2.0.0"):
            find_update_item(root, "2.0.0")

    def test_replaces_release_note_links_with_latest_and_wiki_home_links(self) -> None:
        item = self.make_item(
            f"""
            <sparkle:releaseNotesLink xml:lang="en">https://example.com/old-en</sparkle:releaseNotesLink>
            <sparkle:releaseNotesLink xml:lang="ja">https://example.com/old-ja</sparkle:releaseNotesLink>
            <sparkle:fullReleaseNotesLink>https://example.com/old-full</sparkle:fullReleaseNotesLink>
            <sparkle:fullReleaseNotesLink>https://example.com/duplicate-full</sparkle:fullReleaseNotesLink>
            """
        )

        patch_item(item, argparse.Namespace(repository=REPOSITORY, version=VERSION))

        release_notes_links = item.findall(f"{{{SPARKLE_NS}}}releaseNotesLink")
        self.assertEqual(len(release_notes_links), 2)
        self.assertEqual(
            {
                link.get(f"{{{XML_NS}}}lang"): link.text
                for link in release_notes_links
            },
            {
                "en": (
                    "https://raw.githubusercontent.com/wiki/yaeda/cube-bridge/"
                    "Release-Notes-Latest-en.md"
                ),
                "ja": (
                    "https://raw.githubusercontent.com/wiki/yaeda/cube-bridge/"
                    "Release-Notes-Latest-ja.md"
                ),
            },
        )

        full_release_notes_links = item.findall(
            f"{{{SPARKLE_NS}}}fullReleaseNotesLink"
        )
        self.assertEqual(len(full_release_notes_links), 1)
        self.assertEqual(
            full_release_notes_links[0].text,
            "https://github.com/yaeda/cube-bridge/wiki",
        )

        enclosure = item.find("enclosure")
        self.assertIsNotNone(enclosure)
        assert enclosure is not None
        self.assertEqual(enclosure.get("length"), "42")
        self.assertEqual(
            enclosure.get(f"{{{SPARKLE_NS}}}edSignature"),
            "signed",
        )

    def test_rejects_invalid_enclosure_metadata(self) -> None:
        cases = {
            "missing url": {"url": None},
            "non-release url": {"url": "https://example.com/CubeBridge.dmg"},
            "missing length": {"length": None},
            "missing signature": {"signature": None},
        }

        for name, changes in cases.items():
            with self.subTest(name=name):
                item = self.make_item()
                enclosure = item.find("enclosure")
                self.assertIsNotNone(enclosure)
                assert enclosure is not None

                if "url" in changes:
                    self.set_or_remove(enclosure, "url", changes["url"])
                if "length" in changes:
                    self.set_or_remove(enclosure, "length", changes["length"])
                if "signature" in changes:
                    self.set_or_remove(
                        enclosure,
                        f"{{{SPARKLE_NS}}}edSignature",
                        changes["signature"],
                    )

                with self.assertRaises(SystemExit):
                    patch_item(
                        item,
                        argparse.Namespace(repository=REPOSITORY, version=VERSION),
                    )

    @staticmethod
    def make_item(extra_elements: str = "") -> ET.Element:
        return ET.fromstring(
            f"""
            <item xmlns:sparkle="{SPARKLE_NS}">
              <sparkle:version>{VERSION}</sparkle:version>
              <enclosure
                url="https://github.com/{REPOSITORY}/releases/download/v{VERSION}/CubeBridge-v{VERSION}.dmg"
                length="42"
                sparkle:edSignature="signed"
              />
              {extra_elements}
            </item>
            """
        )

    @staticmethod
    def set_or_remove(element: ET.Element, name: str, value: str | None) -> None:
        if value is None:
            element.attrib.pop(name, None)
        else:
            element.set(name, value)


if __name__ == "__main__":
    unittest.main()
