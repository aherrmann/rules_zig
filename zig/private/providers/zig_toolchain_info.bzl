"""Defines providers for the Zig toolchain rule."""

DOC = """\
Information about how to invoke the Zig executable.
"""

FIELDS = {
    "zig_exe_path": "Path to the Zig executable for the target platform.",
    "zig_lib_path": "Path to the Zig library directory for the target platform.",
    "zig_files": """\
Files required in runfiles to make the Zig executable available.

May be empty if the zig_exe_path points to a locally installed Zig executable.
""",
    "zig_version": "String, The Zig toolchain's version.",
    "zig_cache": "String, The Zig cache directory prefix used for the global and local cache.",
}

ZigToolchainInfo = provider(
    doc = DOC,
    fields = FIELDS,
)
