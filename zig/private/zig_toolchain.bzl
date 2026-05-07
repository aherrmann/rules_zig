"""Implementation of the zig_toolchain rule."""

load("//zig/private/providers:zig_toolchain_info.bzl", "ZigToolchainInfo")

def _zig_built_from_source_transition_impl(_, __):
    return {
        "//zig/settings:built_from_source": False,
    }

_zig_built_from_source_transition = transition(
    implementation = _zig_built_from_source_transition_impl,
    inputs = [],
    outputs = [
        "//zig/settings:built_from_source",
    ],
)

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
        mandatory = True,
        allow_single_file = True,
        executable = True,
        cfg = "exec",
    ),
    "zig_h": attr.label(
        doc = "The Zig header at the root of the Zig library directory.",
        mandatory = True,
        allow_single_file = True,
    ),
    "zig_lib": attr.label(
        doc = "A source directory containing the hermetic Zig library for the target platform.",
        mandatory = True,
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

def _validate_zig_version(ctx, *, zig_exe, zig_lib, zig_version):
    output = ctx.actions.declare_file(ctx.label.name + ".version_validation")
    args = ctx.actions.args()
    args.add_all([zig_exe, zig_version, output])
    ctx.actions.run_shell(
        outputs = [output],
        tools = [zig_exe, zig_lib],
        arguments = [args],
        command = "\n".join([
            'actual_version="$($1 version)"',
            "if [[ $actual_version != $2 ]]; then",
            '  echo "Zig SDK version mismatch. Expected \'$2\' but got \'$actual_version\'." >&2',
            "  exit 1",
            "fi",
            'touch "$3"',
        ]),
        mnemonic = "ZigVersionValidation",
        progress_message = "validate Zig SDK version for toolchain %{label}",
    )
    return output

def _zig_toolchain_impl(ctx):
    zig_exe = ctx.executable.zig_exe
    zig_h = ctx.file.zig_h
    zig_lib = ctx.file.zig_lib
    zig_version = ctx.attr.zig_version
    zig_cache = ctx.attr.zig_cache

    validation = _validate_zig_version(
        ctx,
        zig_exe = zig_exe,
        zig_lib = zig_lib,
        zig_version = zig_version,
    )

    # Validation actions of transitive dependencies do not seem to be picked up
    # by Bazel. So, we need to make the validation output an input of Zig SDK
    # using actions to ensure that it takes place.
    tool_files = [zig_exe, zig_lib, validation]

    # Make the $(tool_BIN) variable available in places like genrules.
    # See https://docs.bazel.build/versions/main/be/make-variables.html#custom_variables
    template_variables = platform_common.TemplateVariableInfo({
        "ZIG_BIN": zig_exe.path,
    })

    default = DefaultInfo(
        files = depset(direct = tool_files),
        runfiles = ctx.runfiles(files = tool_files),
    )

    zigtoolchaininfo = ZigToolchainInfo(
        zig_exe = zig_exe,
        zig_h = zig_h,
        zig_lib = zig_lib,
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
    cfg = _zig_built_from_source_transition,
    attrs = ATTRS,
    doc = DOC,
)
