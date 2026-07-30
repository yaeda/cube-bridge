from __future__ import annotations

import unittest

from scripts.validate_wiki_release_notes import validate_wiki_release_notes


REPOSITORY = "yaeda/cube-bridge"
VERSION = "1.2.3"
WIKI_BASE = f"https://github.com/{REPOSITORY}/wiki"
RAW_BASE = f"https://raw.githubusercontent.com/wiki/{REPOSITORY}"


class ValidateWikiReleaseNotesTests(unittest.TestCase):
    def test_validates_latest_full_and_home_pages(self) -> None:
        pages = self.valid_pages()
        requested_urls: list[str] = []

        def fetch(url: str) -> str:
            requested_urls.append(url)
            return pages[url]

        validate_wiki_release_notes(REPOSITORY, VERSION, fetch=fetch)

        self.assertEqual(
            set(requested_urls),
            {
                f"{RAW_BASE}/Release-Notes-Latest-en.md",
                f"{RAW_BASE}/Release-Notes-Latest-ja.md",
                f"{RAW_BASE}/Release-Notes-Full-en.md",
                f"{RAW_BASE}/Release-Notes-Full-ja.md",
                WIKI_BASE,
            },
        )

    def test_requires_version_in_first_latest_heading(self) -> None:
        pages = self.valid_pages()
        pages[f"{RAW_BASE}/Release-Notes-Latest-en.md"] = (
            "# CubeBridge 1.2.2\n\n"
            f"[Full release notes]({WIKI_BASE}/Release-Notes-Full-en)\n"
        )

        with self.assertRaisesRegex(
            SystemExit,
            "first Markdown heading.*1.2.3",
        ):
            validate_wiki_release_notes(
                REPOSITORY,
                VERSION,
                fetch=pages.__getitem__,
            )

    def test_does_not_accept_a_different_version_containing_target_text(self) -> None:
        pages = self.valid_pages()
        pages[f"{RAW_BASE}/Release-Notes-Latest-en.md"] = (
            "# CubeBridge 11.2.3\n\n"
            f"[Full release notes]({WIKI_BASE}/Release-Notes-Full-en)\n"
        )

        with self.assertRaisesRegex(
            SystemExit,
            "first Markdown heading.*1.2.3",
        ):
            validate_wiki_release_notes(
                REPOSITORY,
                VERSION,
                fetch=pages.__getitem__,
            )

    def test_requires_version_in_each_full_page(self) -> None:
        pages = self.valid_pages()
        pages[f"{RAW_BASE}/Release-Notes-Full-ja.md"] = "# CubeBridge 1.2.2\n"

        with self.assertRaisesRegex(SystemExit, "Full ja.*1.2.3"):
            validate_wiki_release_notes(
                REPOSITORY,
                VERSION,
                fetch=pages.__getitem__,
            )

    def test_requires_language_specific_full_link_in_latest_page(self) -> None:
        pages = self.valid_pages()
        pages[f"{RAW_BASE}/Release-Notes-Latest-ja.md"] = (
            "# CubeBridge 1.2.3\n\n"
            f"[完全なリリースノート]({WIKI_BASE}/Release-Notes-Full-en)\n"
        )

        with self.assertRaisesRegex(SystemExit, "Latest ja.*Full-ja"):
            validate_wiki_release_notes(
                REPOSITORY,
                VERSION,
                fetch=pages.__getitem__,
            )

    @staticmethod
    def valid_pages() -> dict[str, str]:
        return {
            f"{RAW_BASE}/Release-Notes-Latest-en.md": (
                "# CubeBridge 1.2.3\n\n"
                "- A user-facing change.\n\n"
                f"[Full release notes]({WIKI_BASE}/Release-Notes-Full-en)\n"
            ),
            f"{RAW_BASE}/Release-Notes-Latest-ja.md": (
                "# CubeBridge 1.2.3\n\n"
                "- ユーザー向けの変更。\n\n"
                f"[完全なリリースノート]({WIKI_BASE}/Release-Notes-Full-ja)\n"
            ),
            f"{RAW_BASE}/Release-Notes-Full-en.md": (
                "# CubeBridge 1.2.3\n\n- A user-facing change.\n\n"
                "# CubeBridge 1.2.2\n"
            ),
            f"{RAW_BASE}/Release-Notes-Full-ja.md": (
                "# CubeBridge 1.2.3\n\n- ユーザー向けの変更。\n\n"
                "# CubeBridge 1.2.2\n"
            ),
            WIKI_BASE: "Wiki Home",
        }


if __name__ == "__main__":
    unittest.main()
