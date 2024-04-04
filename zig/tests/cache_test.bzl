"""Unit tests for Zig cache handling."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
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

def cache_test_suite(name):
    unittest.suite(
        name,
        partial.make(_env_zig_cache_prefix_test, size = "small"),
    )
