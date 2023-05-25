"""Implementation of the zig_binary rule."""

load("//zig/private/common:filetypes.bzl", "ZIG_SOURCE_EXTENSIONS")
load("//zig/private/common:linker_script.bzl", "zig_linker_script")
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
load(
    "//zig/private/providers:zig_target_info.bzl",
    "zig_target_platform",
)

DOC = """\
Builds a Zig binary.

The target can be built using `bazel build`, corresponding to `zig build-exe`,
and executed using `bazel run`, corresponding to `zig run`.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_binary")

zig_binary(
    name = "my-binary",
    main = "main.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":my-package",  # to support `@import("my-package")`.
    ],
)
```
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
    "linker_script": attr.label(
        doc = "Custom linker script for the target.",
        allow_single_file = True,
        mandatory = False,
    ),
    "_settings": attr.label(
        default = "//zig/settings",
        doc = "Zig build settings.",
        providers = [ZigSettingsInfo],
    ),
}

TOOLCHAINS = [
    "//zig:toolchain_type",
    "//zig/target:toolchain_type",
]

def _zig_binary_impl(ctx):
    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo
    zigtargetinfo = ctx.toolchains["//zig/target:toolchain_type"].zigtargetinfo

    outputs = []

    direct_inputs = []
    transitive_inputs = []

    args = ctx.actions.args()
    args.use_param_file("@%s")

    # TODO[AH] Append `.exe` extension on Windows.
    output = ctx.actions.declare_file(ctx.label.name)
    outputs.append(output)
    args.add(output, format = "-femit-bin=%s")

    direct_inputs.append(ctx.file.main)
    direct_inputs.extend(ctx.files.srcs)
    args.add(ctx.file.main)

    zig_package_dependencies(
        deps = ctx.attr.deps,
        inputs = transitive_inputs,
        args = args,
    )

    zig_linker_script(
        linker_script = ctx.file.linker_script,
        inputs = direct_inputs,
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

    zig_target_platform(
        target = zigtargetinfo,
        args = args,
    )

    ctx.actions.run(
        outputs = outputs,
        inputs = depset(direct = direct_inputs, transitive = transitive_inputs),
        executable = zigtoolchaininfo.target_tool_path,
        tools = zigtoolchaininfo.tool_files,
        arguments = ["build-exe", args],
        mnemonic = "ZigBuildExe",
        progress_message = "Building %{input} as Zig binary %{output}",
        execution_requirements = {tag: "" for tag in ctx.attr.tags},
    )

    default = DefaultInfo(
        executable = output,
        files = depset([output]),
        runfiles = ctx.runfiles(files = [output]),
    )

    return [default]

zig_binary = rule(
    _zig_binary_impl,
    attrs = ATTRS,
    doc = DOC,
    executable = True,
    toolchains = TOOLCHAINS,
)
