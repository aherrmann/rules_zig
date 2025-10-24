"""Analysis tests for Zig multi- or single-zigopt settings."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "unittest")
load("//zig/private/providers:zig_settings_info.bzl", "ZigSettingsInfo")
load(
    ":util.bzl",
    "assert_find_action",
    "assert_flag_set",
    "canonical_label",
)

_SETTINGS_ZIGOPT = canonical_label("@//zig/settings:zigopt")

def _define_settings_zigopt_test(zigopts):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        settings = analysistest.target_under_test(env)[ZigSettingsInfo]

        for zigopt in zigopts:
            assert_flag_set(env, zigopt, settings.args)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_SETTINGS_ZIGOPT: zigopts},
    )

_settings_zigopt_test = _define_settings_zigopt_test(["-mcpu=native", "-flto"])

def _define_build_zigopt_test(mnemonic, zigopts):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        action = assert_find_action(env, mnemonic)

        for zigopt in zigopts:
            assert_flag_set(env, zigopt, action.argv)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_SETTINGS_ZIGOPT: zigopts},
    )

_build_exe_zigopt_test = _define_build_zigopt_test("ZigBuildExe", ["-mcpu-native", "-flto"])

_build_static_lib_zigopt_test = _define_build_zigopt_test("ZigBuildStaticLib", ["-mcpu-native", "-flto"])

_build_shared_lib_zigopt_test = _define_build_zigopt_test("ZigBuildSharedLib", ["-mcpu-native", "-flto"])

_build_test_zigopt_test = _define_build_zigopt_test("ZigBuildTest", ["-mcpu-native", "-flto"])

def zigopt_test_suite(name):
    unittest.suite(
        name,
        # Test Zig zigopt setting on the settings target
        partial.make(_settings_zigopt_test, target_under_test = "//zig/settings", size = "small"),
        # Test Zig zigopt setting on a binary target
        partial.make(_build_exe_zigopt_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        # Test Zig zigopt setting on a library target
        partial.make(_build_static_lib_zigopt_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        # Test Zig zigopt setting on a shared library target
        partial.make(_build_shared_lib_zigopt_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        # Test Zig zigopt setting on a test target
        partial.make(_build_test_zigopt_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
    )
