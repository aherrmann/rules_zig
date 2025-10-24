"""Implementation of the settings rule."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("//zig/private/providers:zig_settings_info.bzl", "ZigSettingsInfo")

DOC = """\
Collection of all Zig build settings.

This rule is only intended for internal use.
It collects the values of all relevant build settings,
such as `@rules_zig//zig/settings:mode`.

You can build the settings target to obtain a JSON file
capturing all configured Zig build settings.
"""

ATTRS = {
    "mode": attr.label(
        doc = "The build mode setting.",
        mandatory = True,
    ),
    "use_cc_common_link": attr.label(
        doc = "Whether to use cc_common.link to link zig binaries and shared libraries.",
        mandatory = True,
    ),
    "threaded": attr.label(
        doc = "The Zig multi- or single-threaded setting.",
        mandatory = True,
    ),
    "zigopt": attr.label(
        doc = "Custom Zig compile options to add to all Zig compile action.",
        mandatory = True,
    ),
}

MODE_ARGS = {
    "debug": ["-O", "Debug"],
    "release_safe": ["-O", "ReleaseSafe"],
    "release_small": ["-O", "ReleaseSmall"],
    "release_fast": ["-O", "ReleaseFast"],
}

MODE_VALUES = ["debug", "release_safe", "release_small", "release_fast"]

THREADED_ARGS = {
    "multi": ["-fno-single-threaded"],
    "single": ["-fsingle-threaded"],
}

THREADED_VALUES = ["multi", "single"]

def _settings_impl(ctx):
    args = []

    use_cc_common_link = ctx.attr.use_cc_common_link[BuildSettingInfo].value

    mode = ctx.attr.mode[BuildSettingInfo].value
    args.extend(MODE_ARGS[mode])

    threaded = ctx.attr.threaded[BuildSettingInfo].value
    args.extend(THREADED_ARGS[threaded])

    zigopts = ctx.attr.zigopt[BuildSettingInfo].value
    args.extend(zigopts)

    settings_info = ZigSettingsInfo(
        mode = mode,
        threaded = threaded,
        use_cc_common_link = use_cc_common_link,
        args = args,
    )

    settings_json = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.write(settings_json, json.encode(settings_info), is_executable = False)

    default_info = DefaultInfo(
        files = depset([settings_json]),
    )

    return [
        default_info,
        settings_info,
    ]

settings = rule(
    _settings_impl,
    attrs = ATTRS,
    doc = DOC,
)
