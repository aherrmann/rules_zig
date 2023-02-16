#!/usr/bin/env python3
"""Reads the supported Bazel versions from bazel_versions.bzl
"""

import json
import sys


def read_supported_bazel_versions(filename):
    """Read SUPPORTED_BAZEL_VERSIONS from the given file.

    Note, this will execute the given file as Python code.
    Do not apply to untrusted input!
    """
    with open(filename, "r") as f:
        content = f.read()
    namespace = {}
    exec(content, {}, namespace)
    if "SUPPORTED_BAZEL_VERSIONS" not in namespace:
        raise RuntimeError(f"SUPPORTED_BAZEL_VERSIONS not defined by {filename}.")
    return namespace["SUPPORTED_BAZEL_VERSIONS"]


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


def parse_bazel_version_spec(version):
    """Produce a stringly representation of the Bazel version.

    This parses any instances of a `//:.bazelversion` file label
    and forwards instances of other stringly version specifications.
    """
    if version.startswith("//"):
        return read_version_file(label_to_path(version))
    else:
        return version


def parse_bazel_versions(specs):
    """Parse a list of versions specifications.

    Reads from any `.bazelversion` files.
    """
    return [parse_bazel_version_spec(spec) for spec in specs]


def main():
    filename = "bazel_versions.bzl"
    specs = read_supported_bazel_versions(filename)
    versions = parse_bazel_versions(specs)
    json.dump(versions, sys.stdout, separators=(",", ":"))


if __name__ == "__main__":
    main()
