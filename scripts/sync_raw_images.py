#!/usr/bin/env python3
"""Sync image tags in raw_images_list.txt with versions.yaml.

versions.yaml is the source of truth. This script rewrites ONLY the tag of each
line in raw_images_list.txt to match the corresponding image in versions.yaml.
Image names and the ordering of raw_images_list.txt are preserved.

The two files use different image names by convention:
  - versions.yaml carries "-base" / "-private" suffixes and an "sb-" prefix
    that raw_images_list.txt strips.
So matching is done on a canonicalized name (registry/repo + stripped name).

Some images (the prometheus family) appear twice with different tags
(pxBackup vs pxMonitor). These are disambiguated by occurrence order, which is
pxBackup-before-pxMonitor in both files.

Exit codes:
  0  files already in sync (nothing written)
  0  files were out of sync and have been corrected (with --write)
  1  a raw line could not be matched to versions.yaml (never happens silently)
"""

import argparse
import os
import sys

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSIONS_FILE = os.path.join(REPO_ROOT, "versions.yaml")
RAW_FILE = os.path.join(REPO_ROOT, "raw_images_list.txt")

NAME_PREFIXES = ("sb-",)
NAME_SUFFIXES = ("-base", "-private")


def canonical_key(image_ref):
    """Return (registry/repo/canonical-name, tag) for an image reference.

    e.g. docker.io/portworx/px-backup-base:3.1.0-staging
         -> ("docker.io/portworx/px-backup", "3.1.0-staging")
    """
    if ":" not in image_ref:
        raise ValueError(f"image ref has no tag: {image_ref!r}")
    path, tag = image_ref.rsplit(":", 1)
    prefix, name = path.rsplit("/", 1) if "/" in path else ("", path)
    for pre in NAME_PREFIXES:
        if name.startswith(pre):
            name = name[len(pre):]
    for suf in NAME_SUFFIXES:
        if name.endswith(suf):
            name = name[: -len(suf)]
    key = f"{prefix}/{name}" if prefix else name
    return key, tag


def collect_versions_tags(versions_path):
    """Return {canonical_key: [tag, tag, ...]} in file order from versions.yaml."""
    with open(versions_path) as fh:
        data = yaml.safe_load(fh)

    tags_by_key = {}

    def walk(node):
        if isinstance(node, dict):
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for item in node:
                walk(item)
        elif isinstance(node, str) and ":" in node and "/" in node:
            key, tag = canonical_key(node)
            tags_by_key.setdefault(key, []).append(tag)

    walk(data.get("modules", {}))
    return tags_by_key


def sync(write):
    tags_by_key = collect_versions_tags(VERSIONS_FILE)

    with open(RAW_FILE) as fh:
        raw_lines = fh.readlines()

    occurrence = {}          # canonical_key -> how many times seen so far in raw
    new_lines = []
    changes = []
    unmatched = []

    for lineno, line in enumerate(raw_lines, 1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            new_lines.append(line)
            continue

        key, current_tag = canonical_key(stripped)
        candidate_tags = tags_by_key.get(key)
        if not candidate_tags:
            unmatched.append((lineno, stripped))
            new_lines.append(line)
            continue

        idx = occurrence.get(key, 0)
        occurrence[key] = idx + 1

        # If every occurrence shares the same tag, order doesn't matter.
        if len(set(candidate_tags)) == 1:
            want_tag = candidate_tags[0]
        elif idx < len(candidate_tags):
            want_tag = candidate_tags[idx]
        else:
            # More occurrences in raw than versions.yaml for a multi-tag image.
            unmatched.append((lineno, stripped))
            new_lines.append(line)
            continue

        if want_tag != current_tag:
            fixed = stripped.rsplit(":", 1)[0] + ":" + want_tag
            eol = line[len(line.rstrip("\n")):] or "\n"
            new_lines.append(fixed + eol)
            changes.append((lineno, current_tag, want_tag, fixed))
        else:
            new_lines.append(line)

    if unmatched:
        print("ERROR: raw_images_list.txt lines with no match in versions.yaml:", file=sys.stderr)
        for lineno, text in unmatched:
            print(f"  line {lineno}: {text}", file=sys.stderr)
        return 1

    if not changes:
        print("raw_images_list.txt is already in sync with versions.yaml.")
        return 0

    print(f"Found {len(changes)} tag mismatch(es):")
    for lineno, old, new, fixed in changes:
        print(f"  line {lineno}: {old} -> {new}   ({fixed})")

    if write:
        with open(RAW_FILE, "w") as fh:
            fh.writelines(new_lines)
        print("raw_images_list.txt updated to match versions.yaml.")
    else:
        print("Run with --write to apply these fixes.")

    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--write",
        action="store_true",
        help="apply fixes to raw_images_list.txt (default: report only)",
    )
    args = parser.parse_args()
    sys.exit(sync(write=args.write))


if __name__ == "__main__":
    main()
