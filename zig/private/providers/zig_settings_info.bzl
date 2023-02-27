"""Defines providers for the settings rule."""

ZigSettingsInfo = provider(
    doc = "Collection of all active Zig build settings.",
    fields = {
        "mode": "The Zig build mode.",
        "threaded": "The Zig multi- or single-threaded setting.",
        "args": "The collected compiler arguments for all active settings.",
    },
)

def zig_settings(*, settings, args):
    """Set flags for the given Zig build settings.

    Args:
      settings: ZigSettingsInfo, The active Zig build settings.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    args.add_all(settings.args)
