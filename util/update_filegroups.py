#!/usr/bin/env python3
"""Generates filegroup targets that capture the files of the rule set.

These are needed for [integration testing][it] to capture all files of the rule
set that have to be forwarded to the integration test for it to be able to
import the rule set successfully.

[it]: https://github.com/bazel-contrib/rules_bazel_integration_test#1-declare-a-filegroup-to-represent-the-parent-workspace-files
"""

import argparse
import os
import python.runfiles.runfiles as runfiles
import shutil
import subprocess

# Add exlusions for packages to skip here.
PACKAGE_PATTERN =  "//...:* - //docs/...:* - //util/...:* - //zig/tests/...:*"

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


def get_bazel():
    """Find the Bazel binary in PATH."""
    if (bazel := shutil.which("bazel")) is None:
        raise RuntimeError("Could not find the bazel executable.")
    return bazel


def get_runfiles():
    r = runfiles.Create()
    env = os.environ
    env.update(r.EnvVars())
    return r, env


def get_buildozer(r, path):
    buildozer = r.Rlocation(os.path.join("rules_zig", path))
    return buildozer


def query_packages(bazel, enable_bzlmod):
    """Query for all the packages that we need to cover.

    A package is a directory that contains a BUILD file in Bazel parlance.
    """
    pattern = PACKAGE_PATTERN
    command = [bazel, "query", pattern, "--output=package"]
    if enable_bzlmod:
        command += ["--enable_bzlmod"]
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


def query_package_sources(bazel, package, enable_bzlmod):
    """Query for all Bazel relevant source files in the given package."""
    pattern = f'kind("source file", //{package}:*)'
    command = [bazel, "query", pattern]
    if enable_bzlmod:
        command += ["--enable_bzlmod"]
    sources = subprocess.check_output(command).decode().split("\n")
    sources.extend(EXTRA_SRCS.get(package, []))
    return sources


def generate_all_files_target(env, buildozer, package, sources, subpackages):
    """Generate an all_files target for the given package."""
    command = [buildozer, "-shorten_labels", "-k", "-f", "-"]
    with subprocess.Popen(command, env=env, stdin=subprocess.PIPE) as proc:
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
    parser = argparse.ArgumentParser(
            prog = "update_filegroups",
            description = "Update generate all_files filegroup targets.")
    parser.add_argument("--buildozer", required=True, type=str, help="Runfiles path to the buildozer binary.")
    parser.add_argument("--enable_bzlmod", action="store_true", help="Pass the '--enable_bzlmod' flag to Bazel.")
    args = parser.parse_args()

    runfiles, runfiles_env = get_runfiles()

    workspace_root = get_workspace_root()
    os.chdir(workspace_root)

    bazel = get_bazel()
    buildozer = get_buildozer(runfiles, args.buildozer)

    packages = query_packages(bazel, args.enable_bzlmod)
    subpackages = calculate_sub_packages(packages)

    for package in packages:
        sources = query_package_sources(bazel, package, args.enable_bzlmod)
        generate_all_files_target(runfiles_env, buildozer, package, sources, subpackages)


if __name__ == "__main__":
    main()
