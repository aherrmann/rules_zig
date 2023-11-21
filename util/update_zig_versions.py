#!/usr/bin/env python3

import requests
import base64
import argparse


_ZIG_INDEX_URL = "https://ziglang.org/download/index.json"
_UNSUPPORTED_VERSIONS = [
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
    response = requests.get(url)
    response.raise_for_status()
    return response.json()


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


def generate_bzl_content(url, data, unsupported_versions, supported_platforms):
    content = [_HEADER.format(url = url)]
    content.append("TOOL_VERSIONS = {")

    for version, platforms in sorted(data.items(), reverse=True):
        if version in unsupported_versions or version == "master":
            continue

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

    content.append('}')

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
