"""Analysis tests for path Zig toolchain selection."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//zig/private/providers:zig_toolchain_info.bzl", "ZigToolchainInfo")
load(":util.bzl", "canonical_label")

_EXTRA_TOOLCHAINS = "//command_line_option:extra_toolchains"
_TOOLCHAIN_PATH = canonical_label("@//zig/tests/path-toolchain:path_zig_toolchain")

def _path_toolchain_test_impl(ctx):
    env = analysistest.begin(ctx)

    toolchain = analysistest.target_under_test(env)[ZigToolchainInfo]
    asserts.equals(env, "path", toolchain.mode)
    asserts.equals(env, "path", toolchain.zig_version)

    return analysistest.end(env)

_path_toolchain_test = analysistest.make(
    _path_toolchain_test_impl,
    config_settings = {
        _EXTRA_TOOLCHAINS: _TOOLCHAIN_PATH,
    },
)

def path_toolchain_test_suite(name):
    unittest.suite(
        name,
        partial.make(
            _path_toolchain_test,
            target_under_test = "//zig:resolved_toolchain",
            size = "small",
        ),
    )
