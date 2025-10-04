"""Implementation of the zig_toolchain rule."""

load("//zig/private/providers:zig_toolchain_info.bzl", "ZigToolchainInfo")

DOC = """\
Defines a Zig compiler toolchain.

The Zig compiler toolchain, defined by the `zig_toolchain` rule,
has builtin cross-compilation support.
Meaning, most Zig toolchains can target any platform supported by Zig
independent of the execution platform.

Therefore, there is no need to couple the execution platform
with the target platform, at least not by default.

This rule configures a Zig compiler toolchain
and the corresponding Bazel execution platform constraints
can be declared using the builtin `toolchain` rule.

You will rarely need to invoke this rule directly.
Instead, use the `zig` module extension
provided by `@rules_zig//zig:extensions.bzl`.

Use the target `@rules_zig//zig:resolved_toolchain`
to access the resolved toolchain for the current execution platform.

See https://bazel.build/extending/toolchains#defining-toolchains.
"""

ATTRS = {
    "zig_exe": attr.label(
        doc = "A hermetically downloaded Zig executable for the target platform.",
        mandatory = False,
        executable = True,
        cfg = "exec",
        allow_single_file = True,
    ),
    "zig_exe_path": attr.string(
        doc = "Path to an existing Zig executable for the target platform.",
        mandatory = False,
    ),
    "zig_lib": attr.label(
        doc = "Path of a hermetically downloaded Zig library for the target platform.",
        mandatory = True,
        allow_single_file = True,
    ),
    "zig_lib_path": attr.string(
        doc = "Absolute path to an existing Zig library for the target platform.",
        mandatory = False,
    ),
    "zig_lib_srcs": attr.label_list(
        doc = "Files of a hermetically downloaded Zig library for the target platform.",
        mandatory = False,
        allow_files = True,
    ),
    "zig_c_header": attr.label(
        doc = "zig.h header file of a hermetically downloaded Zig library for the target platform.",
        mandatory = False,
        allow_single_file = True,
    ),
    "zig_version": attr.string(
        doc = "The Zig toolchain's version.",
        mandatory = True,
    ),
    "zig_cache": attr.string(
        doc = "The Zig cache directory prefix. Used for both the global and local cache.",
        mandatory = True,
    ),
}

def _validate_zig_version(ctx, *, zig_exe_path, zig_files, zig_version):
    output = ctx.actions.declare_file(ctx.label.name + ".version_validation")
    ctx.actions.run_shell(
        outputs = [output],
        tools = zig_files,
        arguments = [zig_exe_path, zig_version, output.path],
        command = "\n".join([
            'actual_version="$($1 version)"',
            "if [[ $actual_version != $2 ]]; then",
            '  echo "Zig SDK version mismatch. Expected \'$2\' but got \'$1\'." >&2',
            "  exit 1",
            "fi",
            'touch "$3"',
        ]),
        mnemonic = "ZigVersionValidation",
        progress_message = "validate Zig SDK version for toolchain %{label}",
    )
    return output

def _zig_toolchain_impl(ctx):
    if ctx.attr.zig_exe and ctx.attr.zig_exe_path:
        fail("Can only set one of zig_exe or zig_exe_path but both were set.")
    if ctx.attr.zig_lib and ctx.attr.zig_lib_path:
        fail("Can only set one of zig_lib or zig_lib_path but both were set.")

    if not ctx.attr.zig_exe and not ctx.attr.zig_exe_path:
        fail("Must set one of zig_exe or zig_exe_path.")
    if not ctx.attr.zig_lib and not ctx.attr.zig_lib_path:
        fail("Must set one of zig_lib or zig_lib_path.")

    if ctx.attr.zig_exe and not ctx.attr.zig_lib:
        fail("Must set zig_lib if zig_exe is set.")
    if not ctx.attr.zig_exe and ctx.attr.zig_lib:
        fail("Can only set zig_lib if zig_exe is set.")

    if ctx.attr.zig_exe_path and not ctx.attr.zig_lib_path:
        fail("Must set zig_lib_path if zig_exe_path is set.")
    if not ctx.attr.zig_exe_path and ctx.attr.zig_lib_path:
        fail("Can only set zig_lib_path if zig_exe_path is set.")

    if ctx.attr.zig_exe and not ctx.attr.zig_lib_srcs:
        fail("Must set zig_lib_srcs if zig_exe is set.")
    if not ctx.attr.zig_exe and ctx.attr.zig_lib_srcs:
        fail("Can only set zig_lib_srcs if zig_exe is set.")

    zig_files = []
    zig_version = ctx.attr.zig_version
    zig_cache = ctx.attr.zig_cache

    if ctx.attr.zig_exe:
        zig_files = depset(direct = ctx.files.zig_lib_srcs + [ctx.file.zig_exe])

    # Make the $(tool_BIN) variable available in places like genrules.
    # See https://docs.bazel.build/versions/main/be/make-variables.html#custom_variables
    template_variables = platform_common.TemplateVariableInfo({
        "ZIG_BIN": ctx.file.zig_exe.path if ctx.file.zig_exe else ctx.attr.zig_exe_path,
    })

    validation = _validate_zig_version(
        ctx,
        zig_exe_path = ctx.file.zig_exe.path if ctx.file.zig_exe else ctx.attr.zig_exe_path,
        zig_files = zig_files,
        zig_version = zig_version,
    )

    # Validation actions of transitive dependencies do not seem to be picked up
    # by Bazel. So, we need to make the validation output an input of Zig SDK
    # using actions to ensure that it takes place.
    zig_files = depset(transitive = [zig_files, depset(direct = [validation])])

    default = DefaultInfo(
        files = zig_files,
        runfiles = ctx.runfiles(transitive_files = zig_files),
    )

    zigtoolchaininfo = ZigToolchainInfo(
        zig_exe = ctx.file.zig_exe,
        zig_exe_path = ctx.attr.zig_exe_path,
        zig_lib = ctx.file.zig_lib,
        zig_lib_path = ctx.attr.zig_lib_path,
        zig_files = zig_files,
        zig_c_header = ctx.file.zig_c_header,
        zig_version = zig_version,
        zig_cache = zig_cache,
    )

    # Export all the providers inside our ToolchainInfo
    # so the resolved_toolchain rule can grab and re-export them.
    toolchain_info = platform_common.ToolchainInfo(
        zigtoolchaininfo = zigtoolchaininfo,
        template_variables = template_variables,
        default = default,
    )

    return [
        default,
        toolchain_info,
        template_variables,
        OutputGroupInfo(_validation = depset(direct = [validation])),
    ]

zig_toolchain = rule(
    implementation = _zig_toolchain_impl,
    attrs = ATTRS,
    doc = DOC,
)
