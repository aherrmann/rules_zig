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
_SETTINGS_HOST_MODE = canonical_label("@//zig/settings:host_mode")
_COMPILATION_MODE = "//command_line_option:compilation_mode"

def _mode_config_settings(mode, compilation_mode = None):
    config_settings = {_SETTINGS_MODE: mode}
    if compilation_mode:
        config_settings[_COMPILATION_MODE] = compilation_mode
    return config_settings

def _define_settings_mode_test(mode, option, expected_mode = None, compilation_mode = None):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        settings = analysistest.target_under_test(env)[ZigSettingsInfo]
        asserts.equals(env, expected_mode or mode, settings.mode)

        mode_option = assert_find_unique_option(env, "-O", settings.args)
        asserts.equals(env, option, mode_option)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = _mode_config_settings(mode, compilation_mode),
    )

_settings_mode_auto_dbg_test = _define_settings_mode_test("auto", "Debug", expected_mode = "debug", compilation_mode = "dbg")
_settings_mode_auto_fastbuild_test = _define_settings_mode_test("auto", "Debug", expected_mode = "debug", compilation_mode = "fastbuild")
_settings_mode_auto_opt_test = _define_settings_mode_test("auto", "ReleaseFast", expected_mode = "release_fast", compilation_mode = "opt")
_settings_mode_debug_test = _define_settings_mode_test("debug", "Debug")
_settings_mode_release_safe_test = _define_settings_mode_test("release_safe", "ReleaseSafe")
_settings_mode_release_small_test = _define_settings_mode_test("release_small", "ReleaseSmall")
_settings_mode_release_fast_test = _define_settings_mode_test("release_fast", "ReleaseFast")

def _define_exec_settings_mode_test(target_mode, host_mode, host_option):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        settings = analysistest.target_under_test(env)[ZigSettingsInfo]
        asserts.equals(env, host_mode, settings.mode)

        mode_option = assert_find_unique_option(env, "-O", settings.args)
        asserts.equals(env, host_option, mode_option)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {
            _SETTINGS_MODE: target_mode,
            _SETTINGS_HOST_MODE: host_mode,
        },
    )

_settings_exec_mode_test = _define_exec_settings_mode_test("debug", "release_fast", "ReleaseFast")

def _define_build_mode_test(mnemonic, mode, option, compilation_mode = None):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        action = assert_find_action(env, mnemonic)
        mode_option = assert_find_unique_option(env, "-O", action.argv)
        asserts.equals(env, option, mode_option)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = _mode_config_settings(mode, compilation_mode),
    )

_build_exe_mode_auto_dbg_test = _define_build_mode_test("ZigBuildExe", "auto", "Debug", compilation_mode = "dbg")
_build_exe_mode_auto_fastbuild_test = _define_build_mode_test("ZigBuildExe", "auto", "Debug", compilation_mode = "fastbuild")
_build_exe_mode_auto_opt_test = _define_build_mode_test("ZigBuildExe", "auto", "ReleaseFast", compilation_mode = "opt")
_build_exe_mode_release_small_opt_test = _define_build_mode_test("ZigBuildExe", "release_small", "ReleaseSmall", compilation_mode = "opt")
_build_exe_mode_debug_test = _define_build_mode_test("ZigBuildExe", "debug", "Debug")
_build_exe_mode_release_safe_test = _define_build_mode_test("ZigBuildExe", "release_safe", "ReleaseSafe")
_build_exe_mode_release_small_test = _define_build_mode_test("ZigBuildExe", "release_small", "ReleaseSmall")
_build_exe_mode_release_fast_test = _define_build_mode_test("ZigBuildExe", "release_fast", "ReleaseFast")

_build_static_lib_mode_debug_test = _define_build_mode_test("ZigBuildStaticLib", "debug", "Debug")
_build_static_lib_mode_release_safe_test = _define_build_mode_test("ZigBuildStaticLib", "release_safe", "ReleaseSafe")
_build_static_lib_mode_release_small_test = _define_build_mode_test("ZigBuildStaticLib", "release_small", "ReleaseSmall")
_build_static_lib_mode_release_fast_test = _define_build_mode_test("ZigBuildStaticLib", "release_fast", "ReleaseFast")

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
        partial.make(_settings_mode_auto_dbg_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_auto_fastbuild_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_auto_opt_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_debug_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_release_safe_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_release_small_test, target_under_test = "//zig/settings", size = "small"),
        partial.make(_settings_mode_release_fast_test, target_under_test = "//zig/settings", size = "small"),
        # Test Zig exec build mode uses host_mode instead of mode
        partial.make(_settings_exec_mode_test, target_under_test = "//zig/tests:exec_settings", size = "small"),
        # Test Zig build mode on a binary target
        partial.make(_build_exe_mode_auto_dbg_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_auto_fastbuild_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_auto_opt_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_release_small_opt_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_debug_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_release_safe_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_release_small_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_mode_release_fast_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        # Test Zig build mode on a library target
        partial.make(_build_static_lib_mode_debug_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_mode_release_safe_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_mode_release_small_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_mode_release_fast_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
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
