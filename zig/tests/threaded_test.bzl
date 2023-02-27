"""Analysis tests for Zig multi- or single-threaded settings."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("@bazel_skylib//lib:partial.bzl", "partial")
load("//zig/private/providers:zig_settings_info.bzl", "ZigSettingsInfo")
load(
    ":util.bzl",
    "assert_flag_set",
    "assert_flag_unset",
)

# TODO[AH] Canonicalize this label (`str(Label(...))`) for `bzlmod` support.
# Note, that canonicalization is not compatible with Bazel 5.3.2, where it will
# strip the requried `@` prefix.
_SETTINGS_THREADED = "@//zig/settings:threaded"

def _define_settings_threaded_test(threaded, flag_set, flag_not_set):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        settings = analysistest.target_under_test(env)[ZigSettingsInfo]
        asserts.equals(env, threaded, settings.threaded)

        assert_flag_set(env, flag_set, settings.args)
        assert_flag_unset(env, flag_not_set, settings.args)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_SETTINGS_THREADED: threaded},
    )

_settings_threaded_single_test = _define_settings_threaded_test("single", "-fsingle-threaded", "-fno-single-threaded")
_settings_threaded_multi_test = _define_settings_threaded_test("multi", "-fno-single-threaded", "-fsingle-threaded")

def threaded_test_suite(name):
    unittest.suite(
        name,
        # Test Zig threaded setting on the settings target
        partial.make(_settings_threaded_single_test, target_under_test = "//zig/settings"),
        partial.make(_settings_threaded_multi_test, target_under_test = "//zig/settings"),
    )
