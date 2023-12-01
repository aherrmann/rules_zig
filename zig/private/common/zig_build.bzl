"""Common implementation of the zig_binary|library|test rules."""

load("//zig/private/common:csrcs.bzl", "zig_csrcs")
load("//zig/private/common:data.bzl", "zig_collect_data", "zig_create_runfiles")
load(
    "//zig/private/common:filetypes.bzl",
    "ZIG_C_SOURCE_EXTENSIONS",
    "ZIG_SOURCE_EXTENSIONS",
)
load("//zig/private/common:linker_script.bzl", "zig_linker_script")
load("//zig/private/common:zig_cache.bzl", "zig_cache_output")
load("//zig/private/common:zig_lib_dir.bzl", "zig_lib_dir")
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

ATTRS = {
    "main": attr.label(
        allow_single_file = ZIG_SOURCE_EXTENSIONS,
        doc = "The main source file.",
        mandatory = True,
    ),
    "srcs": attr.label_list(
        allow_files = ZIG_SOURCE_EXTENSIONS,
        doc = "Other Zig source files required to build the target, e.g. files imported using `@import`.",
        mandatory = False,
    ),
    "extra_srcs": attr.label_list(
        allow_files = True,
        doc = "Other files required to build the target, e.g. files embedded using `@embedFile`.",
        mandatory = False,
    ),
    "csrcs": attr.label_list(
        allow_files = ZIG_C_SOURCE_EXTENSIONS,
        doc = "C source files required to build the target.",
        mandatory = False,
    ),
    "copts": attr.string_list(
        doc = "C compiler flags required to build the C sources of the target.",
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
    "data": attr.label_list(
        allow_files = True,
        doc = "Files required by the target during runtime.",
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

def zig_build_impl(ctx, *, kind):
    """Common implementation for Zig build rules.

    Args:
      ctx: Bazel rule context object.
      kind: String; The kind of the rule, one of `zig_binary`, `zig_library`, `zig_shared_library`, `zig_test`.

    Returns:
      List of providers.
    """
    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo
    zigtargetinfo = ctx.toolchains["//zig/target:toolchain_type"].zigtargetinfo

    executable = None
    files = None
    direct_data = []
    transitive_data = []
    transitive_runfiles = []

    outputs = []

    direct_inputs = []
    transitive_inputs = []

    zig_collect_data(
        data = ctx.attr.data,
        deps = ctx.attr.deps,
        transitive_data = transitive_data,
        transitive_runfiles = transitive_runfiles,
    )

    args = ctx.actions.args()
    args.use_param_file("@%s")

    if kind == "zig_binary" or kind == "zig_test":
        extension = ".exe" if zigtargetinfo.triple.os == "windows" else ""
        output = ctx.actions.declare_file(ctx.label.name + extension)
        outputs.append(output)
        args.add(output, format = "-femit-bin=%s")

        executable = output
        files = depset([output])
        direct_data.append(output)
    elif kind == "zig_library":
        prefix = "" if zigtargetinfo.triple.os == "windows" else "lib"
        extension = ".lib" if zigtargetinfo.triple.os == "windows" else ".a"
        static = ctx.actions.declare_file(prefix + ctx.label.name + extension)
        outputs.append(static)
        args.add(static, format = "-femit-bin=%s")

        files = depset([static])
    elif kind == "zig_shared_library":
        prefix = "" if zigtargetinfo.triple.os == "windows" else "lib"
        extension = ".dll" if zigtargetinfo.triple.os == "windows" else ".so"
        dynamic = ctx.actions.declare_file(prefix + ctx.label.name + extension)
        outputs.append(dynamic)
        args.add(dynamic, format = "-femit-bin=%s")
        args.add(dynamic.basename, format = "-fsoname=%s")

        files = depset([dynamic])
    else:
        fail("Unknown rule kind '{}'.".format(kind))

    direct_inputs.append(ctx.file.main)
    direct_inputs.extend(ctx.files.srcs)
    direct_inputs.extend(ctx.files.extra_srcs)
    args.add(ctx.file.main)

    zig_csrcs(
        copts = ctx.attr.copts,
        csrcs = ctx.files.csrcs,
        inputs = direct_inputs,
        args = args,
    )

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

    zig_lib_dir(
        zigtoolchaininfo = zigtoolchaininfo,
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

    inputs = depset(
        direct = direct_inputs,
        transitive = transitive_inputs,
        order = "preorder",
    )

    if kind == "zig_binary":
        arguments = ["build-exe", args]
        mnemonic = "ZigBuildExe"
        progress_message = "Building %{input} as Zig binary %{output}"
    elif kind == "zig_test":
        arguments = ["test", "--test-no-exec", args]
        mnemonic = "ZigBuildTest"
        progress_message = "Building %{input} as Zig test %{output}"
    elif kind == "zig_library":
        arguments = ["build-lib", args]
        mnemonic = "ZigBuildLib"
        progress_message = "Building %{input} as Zig library %{output}"
    elif kind == "zig_shared_library":
        arguments = ["build-lib", "-dynamic", args]
        mnemonic = "ZigBuildSharedLib"
        progress_message = "Building %{input} as Zig shared library %{output}"
    else:
        fail("Unknown rule kind '{}'.".format(kind))

    ctx.actions.run(
        outputs = outputs,
        inputs = inputs,
        executable = zigtoolchaininfo.zig_exe_path,
        tools = zigtoolchaininfo.zig_files,
        arguments = arguments,
        mnemonic = mnemonic,
        progress_message = progress_message,
        execution_requirements = {tag: "" for tag in ctx.attr.tags},
    )

    default = DefaultInfo(
        executable = executable,
        files = files,
        runfiles = zig_create_runfiles(
            ctx_runfiles = ctx.runfiles,
            direct_data = [],
            transitive_data = transitive_data,
            transitive_runfiles = transitive_runfiles,
        ),
    )

    return [default]
