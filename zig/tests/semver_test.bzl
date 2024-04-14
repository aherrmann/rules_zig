"""Unit tests for semantic version helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private/common:semver.bzl", "semver")

def _sorted_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        ["1.0.0", "2.0.0", "10.0.0"],
        semver.sorted(["2.0.0", "10.0.0", "1.0.0"]),
    )

    asserts.equals(
        env,
        ["1.0.0", "2.0.0", "2.1.0", "2.1.1"],
        semver.sorted(["2.1.1", "2.0.0", "2.1.0", "1.0.0"]),
    )

    return unittest.end(env)

_sorted_test = unittest.make(_sorted_test_impl)

def semver_test_suite(name):
    unittest.suite(
        name,
        partial.make(_sorted_test, size = "small"),
    )
