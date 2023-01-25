"""Implementation of the zig_binary rule."""

DOC = """\
"""

ATTRS = {
}

def _zig_binary_impl(ctx):
    return [DefaultInfo()]

zig_binary = rule(
    _zig_binary_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = ["//zig:toolchain_type"],
)
