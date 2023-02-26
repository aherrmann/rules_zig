"""Implementation of the settings rule."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("//zig/private/providers:zig_settings_info.bzl", "ZigSettingsInfo")

DOC = """\
"""

ATTRS = {
    "mode": attr.label(
        doc = "The build mode setting.",
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

def _settings_impl(ctx):
    args = []

    mode = ctx.attr.mode[BuildSettingInfo].value
    args.extend(MODE_ARGS[mode])

    settings_info = ZigSettingsInfo(
        mode = mode,
        args = args,
    )

    settings_json = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.write(settings_json, settings_info.to_json(), is_executable = False)

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
