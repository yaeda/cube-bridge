#!/usr/bin/env python3
"""Add localized Wiki release notes to a generated Sparkle appcast."""

from __future__ import annotations

import argparse
import xml.etree.ElementTree as ET
from pathlib import Path


SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--appcast", required=True, type=Path)
    parser.add_argument("--version", required=True)
    parser.add_argument("--repository", required=True)
    return parser.parse_args()


def find_update_item(root: ET.Element, version: str) -> ET.Element:
    channel = root.find("channel")
    if channel is None:
        raise SystemExit("appcast.xml is missing channel")

    items = channel.findall("item")
    if not items:
        raise SystemExit("appcast.xml has no update items")

    version_tag = f"{{{SPARKLE_NS}}}version"
    for item in items:
        item_version = item.findtext(version_tag)
        if item_version == version:
            return item

    raise SystemExit(f"appcast.xml has no item for version {version}")


def raw_wiki_url(repository: str, language: str) -> str:
    return f"https://raw.githubusercontent.com/wiki/{repository}/Release-Notes-{language}.md"


def patch_item(item: ET.Element, args: argparse.Namespace) -> None:
    enclosure = item.find("enclosure")
    if enclosure is None:
        raise SystemExit("update item is missing enclosure")

    enclosure_url = enclosure.get("url")
    if not enclosure_url:
        raise SystemExit("update enclosure is missing url")
    if not enclosure_url.startswith(f"https://github.com/{args.repository}/releases/download/"):
        raise SystemExit("update enclosure url does not point to the GitHub Release asset")
    if not enclosure.get("length"):
        raise SystemExit("update enclosure is missing length")
    if not enclosure.get(f"{{{SPARKLE_NS}}}edSignature"):
        raise SystemExit("update enclosure is missing sparkle:edSignature")

    release_notes_tag = f"{{{SPARKLE_NS}}}releaseNotesLink"
    for existing in list(item.findall(release_notes_tag)):
        item.remove(existing)

    for language in ("en", "ja"):
        link = ET.SubElement(item, release_notes_tag)
        link.set("{http://www.w3.org/XML/1998/namespace}lang", language)
        link.text = raw_wiki_url(args.repository, language)


def main() -> None:
    args = parse_args()
    tree = ET.parse(args.appcast)
    root = tree.getroot()
    patch_item(find_update_item(root, args.version), args)
    tree.write(args.appcast, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    main()
