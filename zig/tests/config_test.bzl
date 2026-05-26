"""Analysis tests for Zig configuration settings."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load(":util.bzl", "canonical_label")

_ValueInfo = provider(
    doc = "Returns the value attribute of a value rule.",
    fields = ["value"],
)

def _value_impl(ctx):
    return [_ValueInfo(value = ctx.attr.value)]

_string_value = rule(
    _value_impl,
    attrs = {
        "value": attr.string(mandatory = True),
    },
)

_COMPILATION_MODE = "//command_line_option:compilation_mode"

def _define_config_settings_test(*, flag, value, expected_value = None, compilation_mode = None):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        actual_value = analysistest.target_under_test(env)[_ValueInfo].value
        asserts.equals(env, expected_value or value, actual_value, "Unexpected value for {}".format(flag))

        return analysistest.end(env)

    config_settings = {flag: value}
    if compilation_mode:
        config_settings[_COMPILATION_MODE] = compilation_mode

    return analysistest.make(
        _test_impl,
        config_settings = config_settings,
    )

_SETTINGS_MODE = canonical_label("@//zig/settings:mode")
_SETTINGS_THREADED = canonical_label("@//zig/settings:threaded")

_mode_auto_dbg_test = _define_config_settings_test(flag = _SETTINGS_MODE, value = "auto", expected_value = "debug", compilation_mode = "dbg")
_mode_auto_fastbuild_test = _define_config_settings_test(flag = _SETTINGS_MODE, value = "auto", expected_value = "debug", compilation_mode = "fastbuild")
_mode_auto_opt_test = _define_config_settings_test(flag = _SETTINGS_MODE, value = "auto", expected_value = "release_fast", compilation_mode = "opt")
_mode_debug_test = _define_config_settings_test(flag = _SETTINGS_MODE, value = "debug")
_mode_release_safe_test = _define_config_settings_test(flag = _SETTINGS_MODE, value = "release_safe")
_mode_release_small_test = _define_config_settings_test(flag = _SETTINGS_MODE, value = "release_small")
_mode_release_fast_test = _define_config_settings_test(flag = _SETTINGS_MODE, value = "release_fast")

_threaded_single_test = _define_config_settings_test(flag = _SETTINGS_THREADED, value = "single")
_threaded_multi_test = _define_config_settings_test(flag = _SETTINGS_THREADED, value = "multi")

def config_test_suite(name):
    """Test suite for configuration settings.

    Args:
      name: String, A unique name to assign to the test-suite.
    """
    mode_name = "{}_mode".format(name)
    _string_value(
        name = mode_name,
        value = select({
            "//zig/config/mode:debug": "debug",
            "//zig/config/mode:release_safe": "release_safe",
            "//zig/config/mode:release_small": "release_small",
            "//zig/config/mode:release_fast": "release_fast",
        }),
    )
    threaded_name = "{}_threaded".format(name)
    _string_value(
        name = threaded_name,
        value = select({
            "//zig/config/threaded:single": "single",
            "//zig/config/threaded:multi": "multi",
        }),
    )
    unittest.suite(
        name,
        # mode
        partial.make(_mode_auto_dbg_test, target_under_test = mode_name, size = "small"),
        partial.make(_mode_auto_fastbuild_test, target_under_test = mode_name, size = "small"),
        partial.make(_mode_auto_opt_test, target_under_test = mode_name, size = "small"),
        partial.make(_mode_debug_test, target_under_test = mode_name, size = "small"),
        partial.make(_mode_release_safe_test, target_under_test = mode_name, size = "small"),
        partial.make(_mode_release_small_test, target_under_test = mode_name, size = "small"),
        partial.make(_mode_release_fast_test, target_under_test = mode_name, size = "small"),
        # threaded
        partial.make(_threaded_single_test, target_under_test = threaded_name, size = "small"),
        partial.make(_threaded_multi_test, target_under_test = threaded_name, size = "small"),
    )
