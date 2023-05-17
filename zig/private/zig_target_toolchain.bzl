"""Implementation of the zig_target_toolchain rule."""

load("//zig/private/providers:zig_target_info.bzl", "ZigTargetInfo")

DOC = """\
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
