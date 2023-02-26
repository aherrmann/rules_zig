"""Implementation of the zig_library rule."""

load("//zig/private/common:filetypes.bzl", "ZIG_SOURCE_EXTENSIONS")
load("//zig/private/common:zig_cache.bzl", "zig_cache_output")
load(
    "//zig/private/providers:zig_package_info.bzl",
    "ZigPackageInfo",
    "zig_package_dependencies",
)
load(
    "//zig/private/providers:zig_settings_info.bzl",
    "ZigSettingsInfo",
    "zig_settings",
)

DOC = """\
"""

ATTRS = {
    "main": attr.label(
        allow_single_file = ZIG_SOURCE_EXTENSIONS,
        doc = "The main source file.",
        mandatory = True,
    ),
    "srcs": attr.label_list(
        allow_files = ZIG_SOURCE_EXTENSIONS,
        doc = "Other source files required to build the target.",
        mandatory = False,
    ),
    "deps": attr.label_list(
        doc = "Packages or libraries required to build the target.",
        mandatory = False,
        providers = [ZigPackageInfo],
    ),
    "_settings": attr.label(
        default = "//zig/settings",
        doc = "Zig build settings.",
        providers = [ZigSettingsInfo],
    ),
}

def _zig_library_impl(ctx):
    ziginfo = ctx.toolchains["//zig:toolchain_type"].ziginfo

    outputs = []

    direct_inputs = []
    transitive_inputs = []

    args = ctx.actions.args()
    args.use_param_file("@%s")

    # TODO[AH] Set `.lib` extension on Windows.
    static = ctx.actions.declare_file(ctx.label.name + ".a")
    outputs.append(static)
    args.add(static, format = "-femit-bin=%s")
    # TODO[AH] Support dynamic library output.

    direct_inputs.append(ctx.file.main)
    direct_inputs.extend(ctx.files.srcs)
    args.add(ctx.file.main)

    zig_package_dependencies(
        deps = ctx.attr.deps,
        inputs = transitive_inputs,
        args = args,
    )

    zig_cache_output(
        actions = ctx.actions,
        name = ctx.label.name,
        outputs = outputs,
        args = args,
    )

    zig_settings(
        settings = ctx.attr._settings[ZigSettingsInfo],
        args = args,
    )

    ctx.actions.run(
        outputs = outputs,
        inputs = depset(direct = direct_inputs, transitive = transitive_inputs),
        executable = ziginfo.target_tool_path,
        tools = ziginfo.tool_files,
        arguments = ["build-lib", args],
        mnemonic = "ZigBuildLib",
        progress_message = "Building %{input} as Zig library %{output}",
        execution_requirements = {tag: "" for tag in ctx.attr.tags},
    )

    default = DefaultInfo(
        files = depset([static]),
    )

    return [default]

zig_library = rule(
    _zig_library_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = ["//zig:toolchain_type"],
)
