"""Implementation of the cc_linkopts rule."""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

DOC = """\
Configure C linker flags for targets that depend on this rule.

Generates a target that can be used like a `cc_library` target
"""

ATTRS = {
    "linkopts": attr.string_list(
        doc = """\
Add these flags to the C/C++ linker command.
The `linkopts` attribute is also applied to any target that depends, directly
or indirectly, on this library via `deps` or `cdeps` attributes or similar.
""",
        mandatory = True,
    ),
}

def _cc_linkopts_impl(ctx):
    linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        user_link_flags = ctx.attr.linkopts,
    )

    linking_context = cc_common.create_linking_context(
        linker_inputs = depset(direct = [linker_input]),
    )

    cc_info = CcInfo(
        compilation_context = None,
        linking_context = linking_context,
    )

    return [cc_info]

cc_linkopts = rule(
    _cc_linkopts_impl,
    attrs = ATTRS,
    doc = DOC,
)
