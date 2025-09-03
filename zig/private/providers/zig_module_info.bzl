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
    "main": "File, The main source file of the module.",
    "srcs": "list of File, Other Zig source files that belong to the module.",
    "extra_srcs": "list of File, Other files that belong to the module.",
    "deps": "list of ZigModuleInfo, Import dependencies of this module.",
    "transitive_deps": "depset of ZigModuleInfo, All dependencies required when depending on the module, including transitive dependencies.",
}

ZigModuleInfo = provider(
    fields = FIELDS,
    doc = DOC,
)

def zig_module_info(*, name, canonical_name, main, srcs = [], extra_srcs = [], deps = []):
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
    module = ZigModuleInfo(
        name = name,
        canonical_name = canonical_name,
        main = main,
        srcs = tuple(srcs),
        extra_srcs = tuple(extra_srcs),
        deps = tuple(deps),
        transitive_deps = depset(direct = deps, transitive = [dep.transitive_deps for dep in deps], order = "postorder"),
    )

    return module

def _render_dep(dep):
    return dep.name + "=" + dep.canonical_name

def _add_module_files(inputs, module):
    deps = (module.main,) + module.srcs + module.extra_srcs
    inputs.append(depset(direct = deps))

def _render_args(*, module, inputs, args):
    args.add_all(module.deps, before_each = "--dep", map_each = _render_dep)
    args.add(module.main, format = "-M{}=%s".format(module.canonical_name))
    _add_module_files(inputs, module)

def zig_module_specifications(*, root_module, inputs, args):
    """Collect inputs and flags to build Zig modules.

    Args:
        root_module: TODO(corentin)
        inputs: List of depset of File; mutable, Append the needed inputs to this list.
        args: Args; mutable, Append the needed Zig compiler flags to this object.
    """
    _render_args(
        module = root_module,
        inputs = inputs,
        args = args,
    )
    for dep in root_module.transitive_deps.to_list():
        _render_args(
            module = dep,
            inputs = inputs,
            args = args,
        )
