#!/usr/bin/env python3
"""Determines the list of Bazel versions to test against.

Parses the bazel_binaries extension configuration in MODULE.bazel to extract
the list of Bazel versions.
"""

import json
import re
import sys


def is_label(label):
    """Returns whether the given string is a Bazel label."""
    return label.startswith("//") or label.startswith("@//")


def label_to_path(label):
    """Turn a Bazel label into a file path."""
    if label.startswith("@"):
        raise ValueError(f"External workspace labels are not supported: `{label}`")
    elif label.startswith("//:"):
        return label[3:]
    elif label.startswith("//"):
        return label[2:].replace(":", "/", 1)
    else:
        return label


def read_version_file(filename):
    """Read the first nonempty line in the given file."""
    with open(filename, "r") as f:
        return f.read().lstrip(" \n").partition("\n")[0].rstrip(" \n")


def parse_bazelisk_config(label):
    """Parses a Bazelisk configuration file.

    The Bazelisk configuration file is a text file containing a single line
    with the Bazel version to use.

    Args:
      label: The Bazel label to the Bazelisk configuration file.

    Returns:
      The Bazel version.
    """
    path = label_to_path(label)
    version = read_version_file(path)
    return version


def parse_bazel_versions_from_module(path):
    """Parses the Bazel versions from the MODULE.bazel file.

    The `bazel_binaries` extension is used in the MODULE.bazel file with
    `bazel_binaries.download()` calls in the following forms:
    ```
    bazel_binaries.download(version_file = "//:.bazelversion")
    bazel_binaries.download(version = "7.1.0")
    ```

    Args:
      path: The path to the MODULE.bazel file.

    Returns:
      The list of Bazel versions.
    """
    with open(path, "r") as module_file:
        module_contents = module_file.read()

    download_pattern = r'bazel_binaries\.download\s*\(\s*([^)]+)\s*\)'
    download_calls = re.findall(download_pattern, module_contents, re.MULTILINE | re.DOTALL)

    bazel_versions = []

    for call_args in download_calls:
        version_file_match = re.search(r'version_file\s*=\s*"([^"]+)"', call_args)
        if version_file_match:
            version_file = version_file_match.group(1)
            bazel_versions.append(parse_bazelisk_config(version_file))
            continue

        version_match = re.search(r'version\s*=\s*"([^"]+)"', call_args)
        if version_match:
            version = version_match.group(1)
            bazel_versions.append(version)

    return bazel_versions


def main():
    """Prints the list of Bazel versions to test against."""
    bazel_versions = parse_bazel_versions_from_module("MODULE.bazel")
    json.dump(list(bazel_versions), sys.stdout, separators=(",", ":"))


if __name__ == "__main__":
    main()
