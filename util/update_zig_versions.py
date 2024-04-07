#!/usr/bin/env python3

import urllib.request
import json
import base64
import argparse


_ZIG_INDEX_URL = "https://ziglang.org/download/index.json"

_UNSUPPORTED_VERSIONS = [
    "0.10.1",
    "0.10.0",
    "0.9.1",
    "0.9.0",
    "0.8.1",
    "0.8.0",
    "0.7.1",
    "0.7.0",
    "0.6.0",
    "0.5.0",
    "0.4.0",
    "0.3.0",
    "0.2.0",
    "0.1.1"]

_SUPPORTED_PLATFORMS = [
    "aarch64-linux",
    "aarch64-macos",
    "aarch64-windows",
    "x86_64-linux",
    "x86_64-macos",
    "x86_64-windows",
    "x86-linux",
    "x86-windows"]


def fetch_zig_versions(url):
    with urllib.request.urlopen(url) as response:
        if response.status != 200:
            raise Exception(f"HTTP error: {response.status}")
        data = response.read()
        return json.loads(data.decode('utf-8'))


def convert_sha256(sha256_hex):
    return "sha256-" + base64.b64encode(bytes.fromhex(sha256_hex)).decode()


_HEADER = '''\
"""Mirror of Zig release info.

Generated from {url}.
"""
'''


_PLATFORM = '''\
        "{platform}": struct(
            url = "{url}",
            integrity = "{integrity}",
        ),\
'''


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


def generate_bzl_content(url, data, unsupported_versions, supported_platforms):
    content = [_HEADER.format(url = url)]
    content.append("TOOL_VERSIONS = {")

    latest_release = None

    for version, platforms in sorted(data.items(), key=lambda x: _parse_semver(x[0]), reverse=True):
        if version in unsupported_versions:
            continue

        if latest_release is None and version != "master":
            latest_release = version

        if version == "master":
            version = platforms["version"]

        content.append('    "{}": {{'.format(version))

        for platform, info in sorted(platforms.items()):
            if platform not in supported_platforms or not isinstance(info, dict):
                continue
            content.append(_PLATFORM.format(
                platform = platform,
                url = info["tarball"],
                integrity = convert_sha256(info["shasum"])
            ))

        content.append('    },')

    content.append('}\n')

    if latest_release is not None:
        content.append('LATEST_RELEASE = "{}"\n'.format(latest_release))

    return '\n'.join(content)


def main():
    parser = argparse.ArgumentParser(description="Generate Starlark file for Zig compiler versions.")
    parser.add_argument("--output", type=argparse.FileType('w'), default='-', help="Output file path or '-' for stdout.")
    parser.add_argument("--url", default=_ZIG_INDEX_URL, help="URL to fetch Zig versions JSON")
    parser.add_argument("--unsupported-versions", nargs="*", default=_UNSUPPORTED_VERSIONS, help="List of unsupported Zig versions")
    parser.add_argument("--supported-platforms", nargs="*", default=_SUPPORTED_PLATFORMS, help="List of supported platforms")
    args = parser.parse_args()

    zig_data = fetch_zig_versions(args.url)
    bzl_content = generate_bzl_content(args.url, zig_data, set(args.unsupported_versions), set(args.supported_platforms))

    args.output.write(bzl_content)


if __name__ == "__main__":
    main()
