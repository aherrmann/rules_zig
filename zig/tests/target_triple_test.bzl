"""Unit tests for target triple helpers.
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private/common:zig_target_triple.bzl", "triple")

def _parse_triple_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        triple.make(arch = "x86_64", os = "linux"),
        triple.from_string("x86_64-linux"),
    )

    asserts.equals(
        env,
        triple.make(arch = "arm", os = "linux", abi = "musleabihf"),
        triple.from_string("arm-linux-musleabihf"),
    )

    return unittest.end(env)

_parse_triple_test = unittest.make(_parse_triple_test_impl)

def _print_triple_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "x86_64-linux",
        triple.to_string(triple.make(arch = "x86_64", os = "linux")),
    )

    asserts.equals(
        env,
        "arm-linux-musleabihf",
        triple.to_string(triple.make(arch = "arm", os = "linux", abi = "musleabihf")),
    )

    return unittest.end(env)

_print_triple_test = unittest.make(_print_triple_test_impl)

def target_triple_test_suite(name):
    unittest.suite(
        name,
        _parse_triple_test,
        _print_triple_test,
    )
