"""Implementation of the zig_binary rule."""

load("@bazel_skylib//lib:paths.bzl", "paths")

DOC = """\
"""

ATTRS = {
    "main": attr.label(
        allow_single_file = [".zig"],
        doc = "The main source file.",
        mandatory = True,
    ),
}

def _zig_binary_impl(ctx):
    ziginfo = ctx.toolchains["//zig:toolchain_type"].ziginfo

    # TODO[AH] Append `.exe` extension on Windows.
    output = ctx.actions.declare_file(ctx.label.name)

    local_cache = ctx.actions.declare_directory(paths.join(".zig-cache", "local", ctx.label.name))
    global_cache = ctx.actions.declare_directory(paths.join(".zig-cache", "global", ctx.label.name))

    args = ctx.actions.args()
    args.use_param_file("@%s")

    args.add(output, format = "-femit-bin=%s")
    args.add(ctx.file.main)

    # TODO[AH] Persist or share at least the global cache somehow.
    args.add_all(["--cache-dir", local_cache.path])
    args.add_all(["--global-cache-dir", global_cache.path])

    ctx.actions.run(
        outputs = [output, local_cache, global_cache],
        inputs = [ctx.file.main],
        executable = ziginfo.target_tool_path,
        tools = ziginfo.tool_files,
        arguments = ["build-exe", args],
        mnemonic = "ZigBuildExe",
        progress_message = "Building %{input} as Zig binary %{output}",
    )
    # TODO[AH] Forward tags as execution constraints

    # TODO[AH] analysis test to ensure that default output, files to run executable, and runfiles contain the binary.
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
    toolchains = ["//zig:toolchain_type"],
)
