#!/usr/bin/env python3
"""Determines the list of Bazel versions to test against.

Parses the rules_bazel_integration_testing configuration exposed in
`WORKPACE` to extract the list of Bazel versions.
"""

import ast
import json
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


def parse_bazel_versions(path):
    """Parses the Bazel versions from the WORKSPACE file.

    The `bazel_binaries` macro is invoked in the `WORKSPACE` file in the
    following form:
    ```
    bazel_binaries(versions = [
        "//:.bazelversion",  # A bazelisk configuration file.
        "6.4.0",  # A specific version.
    ])
    ```

    Args:
      path: The path to the defs.bzl file.

    Returns:
      The list of Bazel versions.
    """
    # Open the WORKSPACE file and extract the bazel_binaries macro.
    with open(path, "r") as workspace_file:
        workspace_contents = workspace_file.read()
        bazel_binaries_macro = workspace_contents[
            workspace_contents.find("bazel_binaries(") :]
        bazel_binaries_macro = bazel_binaries_macro[
            : bazel_binaries_macro.find(")") + 1
        ]

    # Parse the bazel_binaries macro to extract the list of Bazel version specifications.
    # Starlark syntax is a subset of Python, so we can use Python's ast module.
    ast_tree = ast.parse(bazel_binaries_macro)
    version_specs = []
    for item in ast_tree.body[0].value.keywords:
        if item.arg == "versions":
            for version in item.value.elts:
                version_specs.append(version.s)

    # Parse the version specifications to extract the list of Bazel versions.
    # Specifications are either a specific version or a Bazel label to a
    # bazelisk configuration file. Pass specific versions on as is, and
    # resolve labels to the file they point to and read the version from the file.
    bazel_versions = []
    for version_spec in version_specs:
        if is_label(version_spec):
            bazel_versions.append(parse_bazelisk_config(version_spec))
        else:
            bazel_versions.append(version_spec)

    return bazel_versions


def main():
    """Prints the list of Bazel versions to test against."""
    bazel_versions = parse_bazel_versions("WORKSPACE")
    json.dump(list(bazel_versions), sys.stdout, separators=(",", ":"))


if __name__ == "__main__":
    main()
