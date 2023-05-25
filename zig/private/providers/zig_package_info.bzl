"""Defines providers for the zig_package rule."""

DOC = """\
Information about a Zig package.

A Zig package is a collection of Zig sources
with a main file that serves as an entry point.

Zig packages are not pre-compiled,
instead the Zig compiler performs whole program compilation.
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

def zig_package_dependencies(*, deps, inputs, args):
    """Collect inputs and flags for Zig package dependencies.

    Args:
      deps: List of Target, Considers the targets that have a ZigPackageInfo provider.
      inputs: List of depset of File; mutable, Append the needed inputs to this list.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    for dep in deps:
        if not ZigPackageInfo in dep:
            continue
        package = dep[ZigPackageInfo]
        inputs.append(package.all_srcs)
        args.add_all(package.flags)
