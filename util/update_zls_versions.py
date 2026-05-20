#!/usr/bin/env python3

import argparse
import json
import urllib.request


_ZLS_INDEX_URL = "https://builds.zigtools.org/index.json"

_UNSUPPORTED_VERSIONS = [
]

_SUPPORTED_PLATFORMS = [
    "aarch64-linux",
    "aarch64-macos",
    "aarch64-windows",
    "x86_64-linux",
    "x86_64-macos",
    "x86_64-windows"]


def fetch_zls_versions(url):
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "rules_zig update_zls_versions.py"},
    )
    with urllib.request.urlopen(request) as response:
        if response.status != 200:
            raise Exception(f"HTTP error: {response.status}")
        data = response.read()
        return json.loads(data.decode('utf-8'))


def _parse_semver(version_str):
    """Split a semantic version into its components.

    Raises an error if the version is malformed.

    If the version contains no pre-release component, then a sentinel of
    `0x10FFFF` is returned. The intent is that it sorts higher than any other
    code-point, therefore making versions without pre-release component sort
    higher than this with.

    If the version is the string `master` then it returns a maximum version
    comprising `float("inf")` components and the pre-release sentinel.

    Returns:
      (major, minor, patch, pre_release)
    """
    max_component = float("inf")
    max_prerelease = chr(0x10FFFF)  # Highest valid code point in Unicode

    if version_str == "master":
        return max_component, max_component, max_component, max_prerelease

    pre_version, *_ = version_str.split("+", maxsplit=1)
    main_version, *pre_release = pre_version.split("-", maxsplit=1)
    major, minor, patch = map(int, main_version.split("."))

    pre_release_segment = pre_release[0] if pre_release else max_prerelease

    return major, minor, patch, pre_release_segment


def generate_json_content(data, unsupported_versions, supported_platforms):
    content = {}

    for version, platforms in sorted(data.items(), key=lambda x: _parse_semver(x[0]), reverse=True):
        if version in unsupported_versions or version == "master":
            continue

        for platform, info in sorted(platforms.items()):
            if platform not in supported_platforms or not isinstance(info, dict):
                continue

            content.setdefault(version, {})[platform] = {
                "tarball": info["tarball"],
                "shasum": info["shasum"],
            }

    return content


def main():
    parser = argparse.ArgumentParser(description="Generate JSON file for ZLS versions.")
    parser.add_argument("--output", type=argparse.FileType('w'), default='-', help="Output file path or '-' for stdout.")
    parser.add_argument("--url", default=_ZLS_INDEX_URL, help="URL to fetch ZLS versions JSON")
    parser.add_argument("--unsupported-versions", nargs="*", default=_UNSUPPORTED_VERSIONS, help="List of unsupported ZLS versions")
    parser.add_argument("--supported-platforms", nargs="*", default=_SUPPORTED_PLATFORMS, help="List of supported platforms")
    args = parser.parse_args()

    zls_data = fetch_zls_versions(args.url)
    json_content = generate_json_content(zls_data, set(args.unsupported_versions), set(args.supported_platforms))

    json.dump(json_content, args.output, indent=2)
    args.output.write("\n")


if __name__ == "__main__":
    main()
