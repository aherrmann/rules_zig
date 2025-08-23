"""Analysis tests for Zig build mode settings."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//zig/private/providers:zig_settings_info.bzl", "ZigSettingsInfo")
load(
    ":util.bzl",
    "assert_find_action",
    "assert_find_unique_option",
    "canonical_label",
)

_SETTINGS_MODE = canonical_label("@//zig/settings:mode")

def _define_settings_mode_test(mode, option):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        settings = analysistest.target_under_test(env)[ZigSettingsInfo]
        asserts.equals(env, mode, settings.mode)

        mode_option = assert_find_unique_option(env, "-O", settings.args)
        asserts.equals(env, option, mode_option)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_SETTINGS_MODE: mode},
    )

_settings_mode_debug_test = _define_settings_mode_test("debug", "Debug")
_settings_mode_release_safe_test = _define_settings_mode_test("release_safe", "ReleaseSafe")
_settings_mode_release_small_test = _define_settings_mode_test("release_small", "ReleaseSmall")
_settings_mode_release_fast_test = _define_settings_mode_test("release_fast", "ReleaseFast")

def _define_build_mode_test(mnemonic, mode, option):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        action = assert_find_action(env, mnemonic)
        mode_option = assert_find_unique_option(env, "-O", action.argv)
        asserts.equals(env, option, mode_option)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_SETTINGS_MODE: mode},
    )

_build_exe_mode_debug_test = _define_build_mode_test("ZigBuildExe", "debug", "Debug")
_build_exe_mode_release_safe_test = _define_build_mode_test("ZigBuildExe", "release_safe", "ReleaseSafe")
_build_exe_mode_release_small_test = _define_build_mode_test("ZigBuildExe", "release_small", "ReleaseSmall")
_build_exe_mode_release_fast_test = _define_build_mode_test("ZigBuildExe", "release_fast", "ReleaseFast")

_build_lib_mode_debug_test = _define_build_mode_test("ZigBuildStaticLib", "debug", "Debug")
_build_lib_mode_release_safe_test = _define_build_mode_test("ZigBuildStaticLib", "release_safe", "ReleaseSafe")
_build_lib_mode_release_small_test = _define_build_mode_test("ZigBuildStaticLib", "release_small", "ReleaseSmall")
_build_lib_mode_release_fast_test = _define_build_mode_test("ZigBuildStaticLib", "release_fast", "ReleaseFast")

_build_shared_lib_mode_debug_test = _define_build_mode_test("ZigBuildSharedLib", "debug", "Debug")
_build_shared_lib_mode_release_safe_test = _define_build_mode_test("ZigBuildSharedLib", "release_safe", "ReleaseSafe")
_build_shared_lib_mode_release_small_test = _define_build_mode_test("ZigBuildSharedLib", "release_small", "ReleaseSmall")
_build_shared_lib_mode_release_fast_test = _define_build_mode_test("ZigBuildSharedLib", "release_fast", "ReleaseFast")

_build_test_mode_debug_test = _define_build_mode_test("ZigBuildTest", "debug", "Debug")
_build_test_mode_release_safe_test = _define_build_mode_test("ZigBuildTest", "release_safe", "ReleaseSafe")
_build_test_mode_release_small_test = _define_build_mode_test("ZigBuildTest", "release_small", "ReleaseSmall")
_build_test_mode_release_fast_test = _define_build_mode_test("ZigBuildTest", "release_fast", "ReleaseFast")

def mode_test_suite(name):
    unittest.suite(
        name,
        # Test Zig build mode on the settings target
        partial.make(_settings_mode_debug_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_release_safe_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_release_small_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_release_fast_test, target_under_test = "//zig/settings", size = "small"),
        # Test Zig build mode on a binary target
        partial.make(_build_exe_mode_debug_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_release_safe_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_release_small_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_release_fast_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        # Test Zig build mode on a library target
        partial.make(_build_lib_mode_debug_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_lib_mode_release_safe_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_lib_mode_release_small_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_lib_mode_release_fast_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        # Test Zig build mode on a shared library target
        partial.make(_build_shared_lib_mode_debug_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_mode_release_safe_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_mode_release_small_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_mode_release_fast_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        # Test Zig build mode on a test target
        partial.make(_build_test_mode_debug_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_mode_release_safe_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_mode_release_small_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_mode_release_fast_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
    )
