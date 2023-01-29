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

def add_package_flags(args, package):
    """Generate the Zig compiler flags to depend on the given package.

    Generates `--pkg-begin` and `--pkg-end` flags required to build a target
    that depends on this package.

    Args:
      args: The Args object to extend with the required flags.
      package: The package to generate flags for.
    """
    args.add_all(["--pkg-begin", package.name, package.main, "--pkg-end"])

def get_package_files(package):
    """Generate a `depset` of the files required to depend on the package."""
    return depset([package.main] + package.srcs)
