"""Defines providers for the target toolchain rule."""

ZigTargetInfo = provider(
    doc = "Defines the compiler configuration for a target platform.",
    fields = {
        "target": "The Zig target platform",
        "args": "The collected compiler arguments for the target platform",
    },
)

def zig_target_platform(*, target, args):
    """Set flags for the given Zig target platform.

    Args:
      target: ZigTargetInfo, The active Zig target platform.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    args.add_all(target.args)
