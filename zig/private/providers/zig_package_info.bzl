"""Defines providers for the zig_module rule."""

DOC = """\
Information about a Zig package.

A Zig package is a collection of Zig sources
with a main file that serves as an entry point.

Zig packages are not pre-compiled,
instead the Zig compiler performs whole program compilation.
"""

FIELDS = {
    "name": "string, The import name of the package.",
    "canonical_name": "string, The canonical name may differ from the import name via remapping.",
    "main": "File, The main source file of the package.",
    "srcs": "list of File, Other Zig source files that belong to the package.",
    "all_mods": "depset of string, All module CLI specifications required when depending on the package.",
    "all_srcs": "depset of File, All source files required when depending on the package.",
}

ZigPackageInfo = provider(
    fields = FIELDS,
    doc = DOC,
)

def zig_module_dependencies(*, deps, extra_deps = [], inputs, args):
    """Collect inputs and flags for Zig package dependencies.

    Args:
      deps: List of Target, Considers the targets that have a ZigPackageInfo provider.
      extra_deps: List of ZigPackageInfo.
      inputs: List of depset of File; mutable, Append the needed inputs to this list.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    mods = []
    names = []

    packages = [
        dep[ZigPackageInfo]
        for dep in deps
        if ZigPackageInfo in dep
    ] + extra_deps

    for package in packages:
        if package.canonical_name != package.name:
            names.append("{}={}".format(package.name, package.canonical_name))
        else:
            names.append(package.name)
        mods.append(package.all_mods)
        inputs.append(package.all_srcs)

    args.add_all(depset(transitive = mods), before_each = "--mod")
    args.add_joined("--deps", names, join_with = ",")
