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
    "transitive_args": "depset of struct, All module CLI specifications required when depending on the module, including transitive dependencies, to be rendered.",
    "transitive_inputs": "depset of File, All build inputs files required when depending on the module, including transitive dependencies.",
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
        args_transitive.append(dep.transitive_args)
        srcs_transitive.append(dep.transitive_inputs)

    arg_direct = _module_args(
        canonical_name = canonical_name,
        main = main,
        deps = deps,
    )
    srcs_direct = [main] + srcs + extra_srcs

    transitive_args = depset(direct = [arg_direct], transitive = args_transitive)
    transitive_inputs = depset(direct = srcs_direct, transitive = srcs_transitive)
    module = ZigModuleInfo(
        name = name,
        canonical_name = canonical_name,
        transitive_args = transitive_args,
        transitive_inputs = transitive_inputs,
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

def _render_args_0_11(args):
    deps = [_render_dep(dep) for dep in args.deps]

    spec = "{name}:{deps}:{main}".format(
        name = args.name,
        main = args.main,
        deps = ",".join(deps),
    )

    return ["--mod", spec]

def _render_args(args):
    rendered = []

    for dep in args.deps:
        rendered.extend(["--dep", _render_dep(dep)])

    rendered.extend(["-M{name}={main}".format(
        name = args.name,
        main = args.main,
    )])

    return rendered

def zig_module_dependencies(*, zig_version, deps, extra_deps = [], args):
    """Collect flags for the Zig main module to depend on other modules.

    Args:
      zig_version: string, The version of the Zig SDK.
      deps: List of Target, Considers the targets that have a ZigModuleInfo provider.
      extra_deps: List of ZigModuleInfo.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    _ = zig_version  # @unused
    deps_args = []

    modules = [
        dep[ZigModuleInfo]
        for dep in deps
        if ZigModuleInfo in dep
    ] + extra_deps

    for module in modules:
        deps_args.append(_render_dep(module))

    args.add_joined("--deps", deps_args, join_with = ",")

def zig_module_specifications(*, zig_version, deps, extra_deps = [], inputs, args):
    """Collect inputs and flags to build Zig modules.

    Args:
      zig_version: string, The version of the Zig SDK.
      deps: List of Target, Considers the targets that have a ZigModuleInfo provider.
      extra_deps: List of ZigModuleInfo.
      inputs: List of depset of File; mutable, Append the needed inputs to this list.
      args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    transitive_args = []

    modules = [
        dep[ZigModuleInfo]
        for dep in deps
        if ZigModuleInfo in dep
    ] + extra_deps

    for module in modules:
        transitive_args.append(module.transitive_args)
        inputs.append(module.transitive_inputs)

    render_args = _render_args
    if zig_version.startswith("0.11."):
        render_args = _render_args_0_11

    args.add_all(depset(transitive = transitive_args), map_each = render_args)
