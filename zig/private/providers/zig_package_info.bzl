"""Defines providers for the zig_package rule."""

DOC = """\
"""

FIELDS = {
    "name": "string, The import name of the package.",
    "main": "File, The main source file of the package.",
    "srcs": "list of File, Other source files that belong to the package.",
    "flags": "list of string, Zig compiler flags requried when depending on the package.",
    "all_srcs": "depset of File, All source files required when depending on the package.",
}

ZigPackageInfo = provider(
    fields = FIELDS,
    doc = DOC,
)

def add_package_flags(args, package):
    """Generate the Zig compiler flags to depend on the given package.

    Generates `--pkg-begin` and `--pkg-end` flags required to build a target
    that depends on this package.

    Args:
      args: The Args object to extend with the required flags.
      package: The package to generate flags for.
    """
    args.add_all(package.flags)

def get_package_files(package):
    """Generate a `depset` of the files required to depend on the package."""
    return package.all_srcs
