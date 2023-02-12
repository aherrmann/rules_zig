#!/usr/bin/env python3
"""Generates filegroup targets that capture the files of the rule set.

These are needed for [integration testing][it] to capture all files of the rule
set that have to be forwarded to the integration test for it to be able to
import the rule set successfully.

[it]: https://github.com/bazel-contrib/rules_bazel_integration_test#1-declare-a-filegroup-to-represent-the-parent-workspace-files
"""

import os
import shutil
import subprocess

# Add exlusions for packages to skip here.
PACKAGE_PATTERN =  "//... - //docs/... - //util/... - //zig/tests/..."

# Add extra source files to capture here.
EXTRA_SRCS = {
    "": [
        ":WORKSPACE",
    ],
}


def get_workspace_root():
    """Read the workspace root directory from the environment."""
    if (root := os.getenv("BUILD_WORKSPACE_DIRECTORY")) is None:
        raise RuntimeError("The workspace root was not found. Execute with `bazel run`.")
    return root


def query_packages(bazel):
    """Query for all the packages that we need to cover.

    A package is a directory that contains a BUILD file in Bazel parlance.
    """
    pattern = PACKAGE_PATTERN
    command = [bazel, "query", pattern, "--output=package"]
    return subprocess.check_output(command).decode().split("\n")


def calculate_sub_packages(packages):
    """Calculate mapping from packages to their sub-packages."""
    subpackages = {}
    for package in packages:
        if package == "":
            continue
        parent = os.path.dirname(package)
        subpackages.setdefault(parent, [])
        subpackages[parent].append(package)
    return subpackages


def query_package_sources(bazel, package):
    """Query for all Bazel relevant source files in the given package."""
    pattern = f'kind("source file", //{package}:*)'
    command = [bazel, "query", pattern]
    sources = subprocess.check_output(command).decode().split("\n")
    sources.extend(EXTRA_SRCS.get(package, []))
    return sources


def generate_all_files_target(buildozer, package, sources, subpackages):
    """Generate an all_files target for the given package."""
    command = [buildozer, "-shorten_labels", "-k", "-f", "-"]
    with subprocess.Popen(command, stdin=subprocess.PIPE) as proc:
        proc.stdin.write(f"delete|//{package}:all_files\n".encode())
        proc.stdin.write(f"new filegroup all_files|//{package}:__pkg__\n".encode())
        proc.stdin.write(f"comment Execute\\ `bazel\\ run\\ //util:update_filegroups`\\ to\\ update\\ this\\ target.|//{package}:all_files\n".encode())
        if package:
            proc.stdin.write(f"add visibility //{os.path.dirname(package)}:__pkg__|//{package}:all_files\n".encode())
        else:
            proc.stdin.write(f"add visibility //visibility:public|//{package}:all_files\n".encode())
        if sources:
            proc.stdin.write(f'add srcs {" ".join(sources)}|//{package}:all_files\n'.encode())
        dependencies = [f"//{subpackage}:all_files" for subpackage in subpackages.get(package, [])]
        if dependencies:
            proc.stdin.write(f'add srcs {" ".join(dependencies)}|//{package}:all_files\n'.encode())


def main():
    workspace_root = get_workspace_root()
    os.chdir(workspace_root)

    bazel = shutil.which("bazel")
    buildozer = shutil.which("buildozer")

    packages = query_packages(bazel)
    subpackages = calculate_sub_packages(packages)

    for package in packages:
        sources = query_package_sources(bazel, package)
        generate_all_files_target(buildozer, package, sources, subpackages)


if __name__ == "__main__":
    main()
