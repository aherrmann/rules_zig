"""Defines providers for the Zig toolchain rule."""

DOC = """\
Information about how to invoke the Zig executable.
"""

FIELDS = {
    "zig_exe": "The Zig executable for the target platform.",
    "zig_lib": "The Zig library directory for the target platform.",
    "zig_files": """\
Files required in runfiles to make the Zig executable available.

May be empty if zig_exe is a locally installed Zig executable.
""",
    "zig_c_header": "The Zig C header file for the target platform.",
    "zig_version": "String, The Zig toolchain's version.",
    "zig_cache": "String, The Zig cache directory prefix used for the global and local cache.",
}

ZigToolchainInfo = provider(
    doc = DOC,
    fields = FIELDS,
)
