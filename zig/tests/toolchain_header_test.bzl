"""Unit tests for Zig toolchain header module."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load(
    "@bazel_skylib//lib:unittest.bzl",
    "analysistest",
    "asserts",
    "unittest",
)
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

def _zig_header_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    cc = target[CcInfo]

    asserts.true(
        env,
        any([
            define.startswith("ZIG_TARGET_MAX_INT_ALIGNMENT")
            for define in cc.compilation_context.defines.to_list()
        ]),
        "ZIG_TARGET_MAX_INT_ALIGNMENT should be defined",
    )

    return analysistest.end(env)

_zig_header_test = analysistest.make(_zig_header_test_impl)

def _test_zig_header(name):
    _zig_header_test(
        name = name,
        target_under_test = "@rules_zig//zig/lib:zig_header",
        size = "small",
    )

def toolchain_header_test_suite(name):
    unittest.suite(
        name,
        partial.make(_max_int_alignment_test, size = "small"),
        partial.make(_test_zig_header),
    )
