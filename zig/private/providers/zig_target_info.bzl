"""Defines providers for the target toolchain rule."""

DOC = """\
Defines the compiler configuration for a target platform.
"""

FIELDS = {
    "target": "The Zig target platform",
    "triple": "The components of the Zig target platform triple",
    "args": "The collected compiler arguments for the target platform",
}

ZigTargetInfo = provider(
    doc = DOC,
    fields = FIELDS,
)

def zig_target_platform(*, target, args):
    """Set flags for the given Zig target platform.

    Args:
      target: ZigTargetInfo, The active Zig target platform.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    args.add_all(target.args)
