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
    "all_args": "depset of struct, All module CLI specifications required when depending on the module, to be rendered.",
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
    args_transitive = []
    srcs_transitive = []

    for dep in deps:
        args_transitive.append(dep.all_args)
        srcs_transitive.append(dep.all_srcs)

    arg_direct = _module_args(
        canonical_name = canonical_name,
        main = main,
        deps = deps,
    )
    srcs_direct = [main] + srcs + extra_srcs

    all_args = depset(direct = [arg_direct], transitive = args_transitive)
    all_srcs = depset(direct = srcs_direct, transitive = srcs_transitive)
    module = ZigModuleInfo(
        name = name,
        canonical_name = canonical_name,
        all_args = all_args,
        all_srcs = all_srcs,
    )

    return module

def _dep_arg(dep):
    if dep.canonical_name != dep.name:
        return struct(name = dep.name, canonical_name = dep.canonical_name)
    else:
        return struct(name = dep.name)

def _module_args(*, canonical_name, main, deps):
    return struct(
        name = canonical_name,
        main = main.path,
        deps = tuple([_dep_arg(dep) for dep in deps]),
    )

def _render_dep(dep):
    dep_spec = dep.name

    if hasattr(dep, "canonical_name") and dep.canonical_name != dep.name:
        dep_spec += "=" + dep.canonical_name

    return dep_spec

def _render_args(args):
    deps = [_render_dep(dep) for dep in args.deps]

    spec = "{name}:{deps}:{main}".format(
        name = args.name,
        main = args.main,
        deps = ",".join(deps),
    )

    return ["--mod", spec]

def zig_module_dependencies(*, deps, extra_deps = [], inputs, args):
    """Collect inputs and flags for Zig module dependencies.

    Args:
      deps: List of Target, Considers the targets that have a ZigModuleInfo provider.
      extra_deps: List of ZigModuleInfo.
      inputs: List of depset of File; mutable, Append the needed inputs to this list.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    transitive_args = []
    deps_args = []

    modules = [
        dep[ZigModuleInfo]
        for dep in deps
        if ZigModuleInfo in dep
    ] + extra_deps

    for module in modules:
        deps_args.append(_render_dep(module))
        transitive_args.append(module.all_args)
        inputs.append(module.all_srcs)

    args.add_all(depset(transitive = transitive_args), map_each = _render_args)
    args.add_joined("--deps", deps_args, join_with = ",")
