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
    "module_context": "struct, per module compilation context required when depending on the module.",
    "transitive_module_contexts": "depset of struct, All compilation context required by direct and transitive dependencies.",
    "transitive_inputs": "depset of File, All dependencies required when depending on the module, including transitive dependencies.",
}

ZigModuleInfo = provider(
    fields = FIELDS,
    doc = DOC,
)

def _zig_module_context(canonical_name, main, deps):
    return struct(
        canonical_name = canonical_name,
        main = main.path,
        dependency_mappings = tuple([struct(name = dep.name, canonical_name = dep.canonical_name) for dep in deps]),
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

    module_context = _zig_module_context(canonical_name, main, deps)

    module = ZigModuleInfo(
        name = name,
        canonical_name = canonical_name,
        module_context = module_context,
        transitive_module_contexts = depset(direct = [dep.module_context for dep in deps], transitive = [dep.transitive_module_contexts for dep in deps], order = "postorder"),
        transitive_inputs = depset(direct = [main] + srcs + extra_srcs, transitive = [dep.transitive_inputs for dep in deps]),
    )

    return module

def _render_per_module_args(module):
    args = []
    for mapping in module.dependency_mappings:
        args.extend(["--dep", "{}={}".format(mapping.name, mapping.canonical_name)])

    args.append("-M{name}={src}".format(name = module.canonical_name, src = module.main))

    return args

def zig_module_specifications(*, root_module, args):
    """Collect inputs and flags to build Zig modules.

    Args:
        root_module: ZigModuleInfo; The root module for which to render args.
        args: Args; mutable, Append the needed Zig compiler flags to this object.
    """

    # The first module is the main module.
    args.add_all(_render_per_module_args(root_module.module_context))
    args.add_all(root_module.transitive_module_contexts, map_each = _render_per_module_args)
