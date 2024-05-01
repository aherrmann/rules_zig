"""Mirror of Zig release info.

Generated from https://ziglang.org/download/index.json.
"""

def _parse(json_string):
    data = json.decode(json_string)
    result = {}
    for version, platforms in data.items():
        for platform, info in platforms.items():
            result.setdefault(version, {})[platform] = struct(
                url = info["tarball"],
                sha256 = info["shasum"],
            )

TOOL_VERSIONS = _parse("""\
$ZIG_VERSIONS_JSON
""")

# vim: ft=bzl
