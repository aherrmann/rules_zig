"""Implementation of the zig_target_toolchain rule."""

load("//zig/private/common:zig_target_triple.bzl", "triple")
load("//zig/private/providers:zig_target_info.bzl", "ZigTargetInfo")

DOC = """\
Defines a Zig target configuration toolchain.

The Zig compiler toolchain, defined by the `zig_toolchain` rule,
has builtin cross-compilation support.
Meaning, most Zig toolchains can target any platform supported by Zig
independent of the execution platform.

Therefore, there is no need to couple the execution platform
with the target platform, at least not by default.

Use this rule to configure a Zig target platform
and declare the corresponding Bazel target platform constraints
using the builtin `toolchain` rule.

Use the target `@rules_zig//zig/target:resolved_toolchain`
to access the resolved toolchain for the current target platform.
You can build this target to obtain a JSON file
capturing the relevant Zig compiler flags.

See https://bazel.build/extending/toolchains#defining-toolchains.

**EXAMPLE**

```bzl
zig_target_toolchain(
    name = "x86_64-linux",
    target = "x86_64-linux",
)

toolchain(
    name = "x86_64-linux_toolchain",
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":x86_64-linux",
    toolchain_type = "@rules_zig//zig/target:toolchain_type",
)
```
"""

ATTRS = {
    "target": attr.string(
        doc = "The value of the -target flag.",
        mandatory = True,
    ),
}

def _zig_target_toolchain(ctx):
    args = []

    target = ctx.attr.target
    args.extend(["-target", target])

    target_info = ZigTargetInfo(
        target = target,
        triple = triple.from_string(target),
        args = args,
    )

    target_json = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.write(target_json, target_info.to_json(), is_executable = False)

    template_variables = platform_common.TemplateVariableInfo({
        "ZIG_TARGET": target,
    })
    default = DefaultInfo(
        files = depset([target_json]),
    )
    toolchain_info = platform_common.ToolchainInfo(
        zigtargetinfo = target_info,
        template_variables = template_variables,
        default = default,
    )

    return [
        default,
        toolchain_info,
        template_variables,
    ]

zig_target_toolchain = rule(
    _zig_target_toolchain,
    attrs = ATTRS,
    doc = DOC,
)
