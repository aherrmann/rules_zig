"""Defines providers for the zig_package rule."""

DOC = """\
"""

FIELDS = {
    "name": "The import name of the package.",
    "main": "The main source file of the package.",
    "srcs": "Other source files required when building the package.",
}

ZigPackageInfo = provider(
    fields = FIELDS,
    doc = DOC,
)
