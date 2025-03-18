"""Unit tests for Zig toolchain header module."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private:zig_toolchain_header.bzl", "max_int_alignment")

def _max_int_alignment_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        8,
        max_int_alignment("arm"),
    )

    asserts.equals(
        env,
        16,
        max_int_alignment("x86_64"),
    )

    return unittest.end(env)

_max_int_alignment_test = unittest.make(
    _max_int_alignment_test_impl,
)

def toolchain_header_test_suite(name):
    unittest.suite(
        name,
        partial.make(_max_int_alignment_test, size = "small"),
    )
