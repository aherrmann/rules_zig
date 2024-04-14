"""Unit tests for semantic version helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _sorted_test_impl(ctx):
    env = unittest.begin(ctx)

    return unittest.end(env)

_sorted_test = unittest.make(_sorted_test_impl)

def semver_test_suite(name):
    unittest.suite(
        name,
        partial.make(_sorted_test, size = "small"),
    )
