"""Defines providers for the settings rule."""

DOC = """\
Collection of all active Zig build settings.
"""

FIELDS = {
    "mode": "The Zig build mode.",
    "threaded": "The Zig multi- or single-threaded setting.",
    "args": "The collected compiler arguments for all active settings.",
}

ZigSettingsInfo = provider(
    doc = DOC,
    fields = FIELDS,
)

def zig_settings(*, settings, args):
    """Set flags for the given Zig build settings.

    Args:
      settings: ZigSettingsInfo, The active Zig build settings.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    args.add_all(settings.args)
