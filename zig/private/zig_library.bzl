"""Implementation of the zig_library rule."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//zig/private:filetypes.bzl", "ZIG_SOURCE_EXTENSIONS")
load(
    "//zig/private/providers:zig_package_info.bzl",
    "ZigPackageInfo",
    "add_package_flags",
    "get_package_files",
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
}

def _zig_library_impl(ctx):
    ziginfo = ctx.toolchains["//zig:toolchain_type"].ziginfo

    # TODO[AH] Set `.lib` extension on Windows.
    static = ctx.actions.declare_file(ctx.label.name + ".a")
    # TODO[AH] Support dynamic library output.

    # TODO[AH] Factor out common zig-cache handling code.
    local_cache = ctx.actions.declare_directory(paths.join(".zig-cache", "local", ctx.label.name))
    global_cache = ctx.actions.declare_directory(paths.join(".zig-cache", "global", ctx.label.name))

    # TODO[AH] Factor out common dependency management code.
    direct_inputs = [ctx.file.main] + ctx.files.srcs
    transitive_inputs = []

    args = ctx.actions.args()
    args.use_param_file("@%s")

    args.add(static, format = "-femit-bin=%s")
    args.add(ctx.file.main)

    # TODO[AH] Factor out common dependency management code.
    for dep in ctx.attr.deps:
        if ZigPackageInfo in dep:
            package = dep[ZigPackageInfo]
            transitive_inputs.append(get_package_files(package))
            add_package_flags(args, package)

    # TODO[AH] Factor out common zig-cache handling code.
    # TODO[AH] Persist or share at least the global cache somehow.
    args.add_all(["--cache-dir", local_cache.path])
    args.add_all(["--global-cache-dir", global_cache.path])

    ctx.actions.run(
        outputs = [static, local_cache, global_cache],
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
