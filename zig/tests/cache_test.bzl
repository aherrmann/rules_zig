"""Unit tests for Zig cache handling."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load(
    "//zig/private/common:zig_cache.bzl",
    "DEFAULT_CACHE_PREFIX",
    "DEFAULT_CACHE_PREFIX_LINUX",
    "DEFAULT_CACHE_PREFIX_MACOS",
    "DEFAULT_CACHE_PREFIX_WINDOWS",
    "VAR_CACHE_PREFIX",
    "VAR_CACHE_PREFIX_LINUX",
    "VAR_CACHE_PREFIX_MACOS",
    "VAR_CACHE_PREFIX_WINDOWS",
    "env_zig_cache_prefix",
)
load("//zig/private/providers:zig_toolchain_info.bzl", "ZigToolchainInfo")
load(
    ":util.bzl",
    "assert_find_action",
    "assert_find_unique_option",
)

def _env_zig_cache_prefix_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        DEFAULT_CACHE_PREFIX_LINUX,
        env_zig_cache_prefix({}, "x86_64-linux"),
    )

    asserts.equals(
        env,
        DEFAULT_CACHE_PREFIX_MACOS,
        env_zig_cache_prefix({}, "aarch64-macos"),
    )

    asserts.equals(
        env,
        DEFAULT_CACHE_PREFIX_WINDOWS,
        env_zig_cache_prefix({}, "x86_64-windows"),
    )

    asserts.equals(
        env,
        DEFAULT_CACHE_PREFIX,
        env_zig_cache_prefix({}, "x86_64-freebsd"),
    )

    default_env = {
        VAR_CACHE_PREFIX: "DEFAULT",
    }

    asserts.equals(
        env,
        "DEFAULT",
        env_zig_cache_prefix(default_env, "aarch64-linux"),
    )

    asserts.equals(
        env,
        "DEFAULT",
        env_zig_cache_prefix(default_env, "x86_64-macos"),
    )

    asserts.equals(
        env,
        "DEFAULT",
        env_zig_cache_prefix(default_env, "aarch64-windows"),
    )

    asserts.equals(
        env,
        "DEFAULT",
        env_zig_cache_prefix(default_env, "aarch64-freebsd"),
    )

    overrides_env = {
        VAR_CACHE_PREFIX_LINUX: "LINUX",
        VAR_CACHE_PREFIX_MACOS: "MACOS",
        VAR_CACHE_PREFIX_WINDOWS: "WINDOWS",
        VAR_CACHE_PREFIX: "DEFAULT",
    }

    asserts.equals(
        env,
        "LINUX",
        env_zig_cache_prefix(overrides_env, "aarch64-linux"),
    )

    asserts.equals(
        env,
        "MACOS",
        env_zig_cache_prefix(overrides_env, "x86_64-macos"),
    )

    asserts.equals(
        env,
        "WINDOWS",
        env_zig_cache_prefix(overrides_env, "aarch64-windows"),
    )

    asserts.equals(
        env,
        "DEFAULT",
        env_zig_cache_prefix(overrides_env, "aarch64-freebsd"),
    )

    return unittest.end(env)

_env_zig_cache_prefix_test = unittest.make(
    _env_zig_cache_prefix_test_impl,
)

def _simple_binary_test_impl(ctx):
    env = analysistest.begin(ctx)
    toolchain = ctx.attr._zig_toolchain[ZigToolchainInfo]

    build = assert_find_action(env, "ZigBuildExe")

    local_cache = assert_find_unique_option(env, "--cache-dir", build.argv)
    asserts.equals(env, toolchain.zig_cache, local_cache)

    global_cache = assert_find_unique_option(env, "--global-cache-dir", build.argv)
    asserts.equals(env, toolchain.zig_cache, global_cache)

    docs = assert_find_action(env, "ZigBuildDocs")

    local_cache = assert_find_unique_option(env, "--cache-dir", docs.argv)
    asserts.equals(env, toolchain.zig_cache, local_cache)

    global_cache = assert_find_unique_option(env, "--global-cache-dir", docs.argv)
    asserts.equals(env, toolchain.zig_cache, global_cache)

    return analysistest.end(env)

_simple_binary_test = analysistest.make(
    _simple_binary_test_impl,
    attrs = {
        "_zig_toolchain": attr.label(default = "//zig:resolved_toolchain"),
    },
)

def cache_test_suite(name):
    unittest.suite(
        name,
        partial.make(_env_zig_cache_prefix_test, size = "small"),
        partial.make(
            _simple_binary_test,
            target_under_test = "//zig/tests/simple-binary:binary",
            size = "small",
        ),
    )
