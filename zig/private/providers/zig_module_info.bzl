"""Defines providers for the zig_module rule."""

DOC = """\
Information about a Zig module.

A Zig module is a collection of Zig sources
with a main file that serves as an entry point.

Zig modules are not pre-compiled,
instead the Zig compiler performs whole program compilation.
"""

FIELDS = {
    "name": "string, The import name of the module.",
    "canonical_name": "string, The canonical name may differ from the import name via remapping.",
    "all_mods": "depset of string, All module CLI specifications required when depending on the module.",
    "all_srcs": "depset of File, All source files required when depending on the module.",
}

ZigModuleInfo = provider(
    fields = FIELDS,
    doc = DOC,
)

def zig_module_info(*, name, canonical_name, main, srcs, extra_srcs, deps):
    """Create `ZigModuleInfo` for a new Zig module.

    Args:
      name: string, The import name of the module.
      canonical_name: string, The canonical name may differ from the import name via remapping.
      main: File, The main source file of the module.
      srcs: list of File, Other Zig source files that belong to the module.
      extra_srcs: list of File, Other files that belong to the module.
      deps: list of ZigModuleInfo, Import dependencies of this module.

    Returns:
      `ZigModuleInfo`
    """
    imports = []
    mods_transitive = []
    srcs_transitive = []

    for dep in deps:
        if dep.canonical_name != dep.name:
            imports.append("{}={}".format(dep.name, dep.canonical_name))
        else:
            imports.append(dep.name)

        mods_transitive.append(dep.all_mods)
        srcs_transitive.append(dep.all_srcs)

    mod_direct = "{name}:{imports}:{src}".format(
        name = canonical_name,
        imports = ",".join(imports),
        src = main.path,
    )
    all_mods = depset(direct = [mod_direct], transitive = mods_transitive)
    all_srcs = depset(direct = [main] + srcs + extra_srcs, transitive = srcs_transitive)
    module = ZigModuleInfo(
        name = name,
        canonical_name = canonical_name,
        all_mods = all_mods,
        all_srcs = all_srcs,
    )

    return module

def zig_module_dependencies(*, deps, extra_deps = [], inputs, args):
    """Collect inputs and flags for Zig module dependencies.

    Args:
      deps: List of Target, Considers the targets that have a ZigModuleInfo provider.
      extra_deps: List of ZigModuleInfo.
      inputs: List of depset of File; mutable, Append the needed inputs to this list.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    mods = []
    names = []

    modules = [
        dep[ZigModuleInfo]
        for dep in deps
        if ZigModuleInfo in dep
    ] + extra_deps

    for module in modules:
        if module.canonical_name != module.name:
            names.append("{}={}".format(module.name, module.canonical_name))
        else:
            names.append(module.name)
        mods.append(module.all_mods)
        inputs.append(module.all_srcs)

    args.add_all(depset(transitive = mods), before_each = "--mod")
    args.add_joined("--deps", names, join_with = ",")
