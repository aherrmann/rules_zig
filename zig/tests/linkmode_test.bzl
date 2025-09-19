"""Analysis tests for Zig build linkmode settings."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//zig/private/providers:zig_settings_info.bzl", "ZigSettingsInfo")
load(
    ":util.bzl",
    "assert_find_actions_in_exact_order",
    "canonical_label",
)

_SETTINGS_LINKMODE = canonical_label("@//zig/settings:linkmode")

def _define_settings_linkmode_test(linkmode):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        settings = analysistest.target_under_test(env)[ZigSettingsInfo]
        asserts.equals(env, linkmode, settings.linkmode)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_SETTINGS_LINKMODE: linkmode},
    )

_settings_linkmode_cc_test = _define_settings_linkmode_test("cc")
_settings_linkmode_zig_test = _define_settings_linkmode_test("zig")

def _define_build_linkmode_test(mnemonics, linkmode):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        assert_find_actions_in_exact_order(env, mnemonics)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_SETTINGS_LINKMODE: linkmode},
    )

_build_exe_linkmode_cc_test = _define_build_linkmode_test(["ZigBuildLib", "CppLink"], "cc")
_build_exe_linkmode_zig_test = _define_build_linkmode_test(["ZigBuildExe"], "zig")

_build_static_lib_linkmode_cc_test = _define_build_linkmode_test(["ZigBuildStaticLib"], "cc")
_build_static_lib_linkmode_zig_test = _define_build_linkmode_test(["ZigBuildStaticLib"], "zig")

_build_shared_lib_linkmode_cc_test = _define_build_linkmode_test(["ZigBuildLib", "CppLink"], "cc")
_build_shared_lib_linkmode_zig_test = _define_build_linkmode_test(["ZigBuildSharedLib"], "zig")

_build_test_linkmode_cc_test = _define_build_linkmode_test(["ZigBuildLib", "CppLink"], "cc")
_build_test_linkmode_zig_test = _define_build_linkmode_test(["ZigBuildTest"], "zig")

def linkmode_test_suite(name):
    unittest.suite(
        name,
        # Test Zig build mode on the settings target
        partial.make(_settings_linkmode_cc_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_linkmode_zig_test, target_under_test = "//zig/settings", size = "small"),
        # Test Zig build linkmode on a binary target
        partial.make(_build_exe_linkmode_cc_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_linkmode_zig_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        # Test Zig build linkmode on a library target
        partial.make(_build_static_lib_linkmode_cc_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_linkmode_zig_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        # Test Zig build linkmode on a shared library target
        partial.make(_build_shared_lib_linkmode_cc_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_linkmode_zig_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        # Test Zig build linkmode on a test target
        partial.make(_build_test_linkmode_cc_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_linkmode_zig_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
    )
