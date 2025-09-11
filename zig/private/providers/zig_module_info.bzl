"""Defines providers for the zig_module rule."""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

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
    "cc_info": "CcInfo or None, TODO(cerisier).",
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

def zig_module_info(*, name, canonical_name, main, srcs = [], extra_srcs = [], deps = [], cdeps = [], translated_cdeps = []):
    """Create `ZigModuleInfo` for a new Zig module.

    Args:
      name: string, The import name of the module.
      canonical_name: string, The canonical name may differ from the import name via remapping.
      main: File, The main source file of the module.
      srcs: list of File, Other Zig source files that belong to the module.
      extra_srcs: list of File, Other files that belong to the module.
      deps: list of ZigModuleInfo, Import dependencies of this module.
      cdeps: list of CcInfo, C dependencies of this module that should be not be used in the global translate-c module.
      translated_cdeps: list of CcInfo, C dependencies of this module that should be used in the global translate-c module.

    Returns:
      `ZigModuleInfo`
    """
    cc_infos = []
    cc_infos.extend(cdeps)
    cc_infos.extend([dep.cc_info for dep in deps if dep.cc_info])
    if translated_cdeps:
        cc_infos.append(CcInfo(
            linking_context = cc_common.merge_linking_contexts(linking_contexts = [dep.linking_context for dep in translated_cdeps]),
        ))

    cc_info = cc_common.merge_cc_infos(direct_cc_infos = cc_infos) if cc_infos else None

    module_context = _zig_module_context(canonical_name, main, deps)

    module = ZigModuleInfo(
        name = name,
        canonical_name = canonical_name,
        module_context = module_context,
        cc_info = cc_info,
        transitive_module_contexts = depset(direct = [dep.module_context for dep in deps], transitive = [dep.transitive_module_contexts for dep in deps], order = "postorder"),
        transitive_inputs = depset(direct = [main] + srcs + extra_srcs, transitive = [dep.transitive_inputs for dep in deps], order = "preorder"),
    )

    return module

def _render_per_module_args_impl(module, has_c_module):
    args = []
    for mapping in module.dependency_mappings:
        args.extend(["--dep", "{}={}".format(mapping.name, mapping.canonical_name)])
    if has_c_module:
        args.extend(["--dep", "c"])

    args.append("-M{name}={src}".format(name = module.canonical_name, src = module.main))

    return args

def _render_per_module_args_with_c(module):
    return _render_per_module_args_impl(module, has_c_module = True)

def _render_per_module_args(module):
    return _render_per_module_args_impl(module, has_c_module = False)

def zig_module_specifications(*, root_module, args, c_module = None):
    """Collect inputs and flags to build Zig modules.

    Args:
        root_module: ZigModuleInfo; The root module for which to render args.
        args: Args; mutable, Append the needed Zig compiler flags to this object.
        c_module: ZigModuleInfo or None; If not None, the global C translation module to depend on.
    """

    # The first module is the main module.
    if c_module:
        args.add_all(_render_per_module_args_with_c(root_module.module_context))
        args.add_all(root_module.transitive_module_contexts, map_each = _render_per_module_args_with_c)
        args.add(c_module.module_context.main, format = "-Mc=%s")
    else:
        args.add_all(_render_per_module_args(root_module.module_context))
        args.add_all(root_module.transitive_module_contexts, map_each = _render_per_module_args)
