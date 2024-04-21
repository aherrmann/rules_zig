"""Unit tests for Zig module extension."""

load("@bazel_skylib//lib:unittest.bzl", "unittest")

def bzlmod_zig_test_suite(name):
    unittest.suite(
        name,
    )
