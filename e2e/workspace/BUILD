"""Provides a simple way to test your rules as an external workspace.
Add a basic smoke-test target below.
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
# load("rules_zig//zig:defs.bzl", "...")

# Replace with a usage of your rule/macro
filegroup(name = "empty")

genrule(
    name = "zig_version",
    outs = ["zig_version.actual"],
    cmd = "$(ZIG_BIN) version > $(OUTS)",
    toolchains = ["@rules_zig//zig:resolved_toolchain"],
)

build_test(
    name = "smoke_test",
    targets = [
        # targets you add above
        ":empty",
        ":zig_version",
    ],
)

diff_test(
    name = "zig_version_test",
    file1 = ":zig_version.expected",
    file2 = ":zig_version.actual",
)
