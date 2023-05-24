"""Defines providers for the Zig toolchain rule."""

ZigToolchainInfo = provider(
    doc = "Information about how to invoke the Zig executable.",
    fields = {
        "target_tool_path": "Path to the Zig executable for the target platform.",
        "tool_files": """Files required in runfiles to make the Zig executable available.

May be empty if the target_tool_path points to a locally installed Zig executable.""",
    },
)
