#!/usr/bin/env python3
"""Validate the Wiki release-note pages required for a release."""

from __future__ import annotations

import argparse
import re
import urllib.request
from collections.abc import Callable


FetchText = Callable[[str], str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", required=True)
    parser.add_argument("--version", required=True)
    return parser.parse_args()


def fetch_text(url: str) -> str:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "CubeBridge-release-validation"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


def contains_version(text: str, version: str) -> bool:
    version_pattern = rf"(?<![0-9A-Za-z.])v?{re.escape(version)}(?![0-9A-Za-z.+-])"
    return re.search(version_pattern, text) is not None


def validate_wiki_release_notes(
    repository: str,
    version: str,
    *,
    fetch: FetchText = fetch_text,
) -> None:
    raw_base = f"https://raw.githubusercontent.com/wiki/{repository}"
    wiki_home_url = f"https://github.com/{repository}/wiki"
    pages: dict[str, str] = {}

    urls = {
        "Wiki Home": wiki_home_url,
        **{
            f"{page_type.title()} {language}": (
                f"{raw_base}/Release-Notes-{page_type.title()}-{language}.md"
            )
            for page_type in ("latest", "full")
            for language in ("en", "ja")
        },
    }

    for label, url in urls.items():
        try:
            pages[label] = fetch(url)
        except Exception as error:
            raise SystemExit(f"Unable to fetch {label} at {url}: {error}") from error

    for language in ("en", "ja"):
        latest_label = f"Latest {language}"
        full_label = f"Full {language}"
        latest_text = pages[latest_label]
        full_text = pages[full_label]
        full_url = f"{wiki_home_url}/Release-Notes-Full-{language}"

        first_heading = re.search(
            r"(?m)^[ \t]{0,3}#{1,6}[ \t]+(.+?)\s*$",
            latest_text,
        )
        if first_heading is None or not contains_version(
            first_heading.group(1),
            version,
        ):
            raise SystemExit(
                f"{latest_label} first Markdown heading must contain version {version}"
            )

        if not contains_version(full_text, version):
            raise SystemExit(f"{full_label} must contain version {version}")

        if full_url not in latest_text:
            raise SystemExit(f"{latest_label} must link to {full_url}")


def main() -> None:
    args = parse_args()
    validate_wiki_release_notes(args.repository, args.version)


if __name__ == "__main__":
    main()
