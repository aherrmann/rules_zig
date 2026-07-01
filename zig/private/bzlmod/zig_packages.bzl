"""Implementation of the `zig_packages` module extension."""

load("@rules_zig_host_toolchain//:toolchain.bzl", "zig_cache", "zig_path")
load("//zig/private/repo:zig_deps_hub.bzl", "zig_deps_hub")
load("//zig/private/repo:zig_package.bzl", "zig_package")

from_file = tag_class(
    attrs = {
        "build_zig_zon": attr.label(
            doc = "A `build.zig.zon` manifest to resolve Zig dependencies for.",
            mandatory = True,
            allow_single_file = True,
        ),
    },
)

system_library = tag_class(
    attrs = {
        "name": attr.string(
            doc = "The name of the system library as passed to `linkSystemLibrary` in a package's `build.zig`.",
            mandatory = True,
        ),
        "lib": attr.label(
            doc = "A `cc_library` that provides the named system library.",
            mandatory = True,
        ),
    },
)

system_integration = tag_class(
    attrs = {
        "name": attr.string(
            doc = "The name of an optional system integration (`systemIntegrationOption`) to enable.",
            mandatory = True,
        ),
    },
)

config = tag_class(
    attrs = {
        "name": attr.string(mandatory = True, doc = "Module-local name of this configuration cell."),
        "optimize": attr.string(doc = "Zig optimize mode: debug | release_safe | release_small | release_fast."),
        "select_on": attr.string_list(doc = "Extra Bazel condition labels ANDed into this cell's `select()` branch."),
        "zig_flags": attr.string_list(doc = "Extra `-D` build options (NAME=VALUE) passed to the configurer for this cell."),
    },
)

configure = tag_class(
    attrs = {
        "configs": attr.string_list(mandatory = True, doc = "Ordered config names that apply."),
        "fallback": attr.string(mandatory = True, doc = "The config name used for the `//conditions:default` branch."),
        "package": attr.string(doc = "If set, override the matrix for the named package only; otherwise global."),
        "version": attr.string(doc = "Disambiguate `package` by version."),
    },
)

_OPTIMIZE_MODES = {
    "debug": "Debug",
    "release_safe": "ReleaseSafe",
    "release_small": "ReleaseSmall",
    "release_fast": "ReleaseFast",
}

def resolve_cell(tag):
    """Resolve a `config` tag into a build-configuration matrix cell.

    `optimize` expands to `//zig/config/mode:mode` and `-Doptimize=Mode`;
    `select_on` is appended verbatim and `zig_flags` become `-DNAME=VALUE`.

    Args:
      tag: a `config` tag.

    Returns:
      `(error, cell)`, `cell`: `struct(name, select_on, zig_options)`, where
      `zig_options` is a list of `-DNAME=VALUE` Zig build option flags.
    """
    select_on = []
    zig_options = []

    if tag.optimize:
        mode = _OPTIMIZE_MODES.get(tag.optimize)
        if mode == None:
            return ("config '{}' has unknown optimize mode '{}'".format(tag.name, tag.optimize), None)
        select_on.append("@rules_zig//zig/config/mode:" + tag.optimize)
        zig_options.append("-Doptimize=" + mode)

    select_on.extend(tag.select_on)

    for flag in tag.zig_flags:
        if "=" not in flag:
            return ("config '{}' flag '{}' is not NAME=VALUE".format(tag.name, flag), None)
        zig_options.append("-D" + flag)

    return (None, struct(name = tag.name, select_on = select_on, zig_options = zig_options))

def check_cells(package_name, cells):
    """Validate and deduplicate a package's matrix cells.

    Args:
      package_name: the package the cells belong to, for error messages.
      cells: the package's cells, each a
        `struct(name, select_on, zig_options, config_setting)`.

    Returns:
      (error, cells), the fallback cells followed by the deduplicated
        non-fallback cells.
    """
    fallbacks = [cell for cell in cells if cell.config_setting == ""]
    nonfallback = [cell for cell in cells if cell.config_setting != ""]

    deduped = []
    by_conditions = {}
    for cell in nonfallback:
        if not cell.select_on:
            return ("package '{}' config '{}' has no select conditions".format(package_name, cell.name), None)

        key = tuple(sorted(cell.select_on))
        existing = by_conditions.get(key)
        if existing != None:
            if existing.zig_options != cell.zig_options:
                return ("package '{}' configs '{}' and '{}' share conditions but differ in build options".format(
                    package_name,
                    existing.name,
                    cell.name,
                ), None)
            continue
        by_conditions[key] = cell
        deduped.append(cell)

    for outer in deduped:
        for inner in deduped:
            if outer.name == inner.name:
                continue
            if len(outer.select_on) < len(inner.select_on) and all([c in inner.select_on for c in outer.select_on]):
                return ("package '{}' config '{}' conditions are a subset of '{}'; they would match ambiguously".format(
                    package_name,
                    outer.name,
                    inner.name,
                ), None)

    return (None, fallbacks + deduped)

def package_name_version(key):
    """Split a URL package's hash key into its name and version.

    Args:
      key: a URL package's Zig hash key, `<name>-<version>-<digest>`.
        `version` may contain `-` (e.g. `0.5.0-dev`).

    Returns:
      (name, version).
    """
    name, _, rest = key.partition("-")
    return name, rest.rpartition("-")[0]

def package_cells(key, cells_by_name, global_configure, per_package_configure):
    """Resolve the matrix cells a URL package is configured under.

    Args:
      key: the package's Zig hash key.
      cells_by_name: map from config name to its `struct(name, select_on, zig_options)`.
      global_configure: the global `configure` (with `configs`/`fallback`), or None.
      per_package_configure: map from `(name, version)` to a `configure`.

    Returns:
      (error, cells): cells is the ordered list of `struct(name, select_on,
        zig_options, config_setting)`, or None if the package is configured
        once at the host default.
    """
    name, version = package_name_version(key)

    selected = per_package_configure.get((name, version))
    if selected == None:
        selected = per_package_configure.get((name, ""))
    if selected == None:
        selected = global_configure
    if selected == None:
        return (None, None)

    if selected.fallback not in selected.configs:
        return ("package '{}' configure fallback '{}' is not among its configs".format(name, selected.fallback), None)

    cells = []
    seen = {}
    for config_name in selected.configs:
        if config_name in seen:
            return ("package '{}' configure lists config '{}' more than once".format(name, config_name), None)
        seen[config_name] = True
        cell = cells_by_name.get(config_name)
        if cell == None:
            return ("package '{}' configure references unknown config '{}'".format(name, config_name), None)
        cells.append(struct(
            name = cell.name,
            select_on = cell.select_on,
            zig_options = cell.zig_options,
            config_setting = "" if config_name == selected.fallback else cell.name,
        ))

    return check_cells(name, cells)

def collect_configs(modules):
    """Collect the build-configuration matrix from the root module's tags.

    Configurations from non-root modules are ignored (their names are returned
    so the caller can warn).

    Args:
      modules: sequence of bazel_module, the extension's modules with
        `tags.config` and `tags.configure`.

    Returns:
      (error, result), where result is `struct(cells_by_name, global_configure,
        per_package_configure, ignored)`.
    """
    ignored = []
    cells_by_name = {}
    global_configure = None
    per_package_configure = {}

    for mod in modules:
        if not mod.is_root:
            if mod.tags.config or mod.tags.configure:
                ignored.append(mod.name)
            continue

        for tag in mod.tags.config:
            error, cell = resolve_cell(tag)
            if error != None:
                return (error, None)
            existing = cells_by_name.get(tag.name)
            if existing != None and existing != cell:
                return ("conflicting config tags named '{}'".format(tag.name), None)
            cells_by_name[tag.name] = cell

        for tag in mod.tags.configure:
            if tag.package:
                key = (tag.package, tag.version)
                if key in per_package_configure:
                    return ("multiple configure tags for package '{}'".format(tag.package), None)
                per_package_configure[key] = tag
            elif global_configure != None:
                return ("at most one global configure tag is allowed", None)
            else:
                global_configure = tag

    return (None, struct(
        cells_by_name = cells_by_name,
        global_configure = global_configure,
        per_package_configure = per_package_configure,
        ignored = ignored,
    ))

def _resolve_graph(module_ctx, zig, zon2json, cache, pkg_dir, manifests):
    result = module_ctx.execute(
        [zig, "run", "--cache-dir", cache, "--global-cache-dir", cache, zon2json, "--", zig, cache, str(pkg_dir)] +
        [str(manifest) for manifest in manifests],
    )
    if result.return_code != 0:
        fail("Failed to resolve the Zig dependency graph:\n{}".format(result.stderr))
    return json.decode(result.stdout)

def _portable_key(key, pkg_dir, manifest_labels):
    """Map a path dependency's absolute directory to a portable key.

    Absolute paths are local to a single resolution and must not be persisted.
    Path dependencies inside the package directory become package-relative keys;
    those in module source become the label of their provided manifest.
    """
    if key.startswith(pkg_dir + "/"):
        return key[len(pkg_dir) + 1:]

    manifest = key + "/build.zig.zon"
    if manifest in manifest_labels:
        return manifest_labels[manifest]

    fail("Zig path dependency at '{}' has no provided manifest; add its `build.zig.zon` as a `from_file` tag.".format(key))

def _localize_paths(graph, pkg_dir, manifest_labels):
    remap = {
        key: _portable_key(key, pkg_dir, manifest_labels)
        for key, package in graph["packages"].items()
        if package["path"] != None
    }

    packages = {}
    for key, package in graph["packages"].items():
        package["deps"] = {name: remap.get(child, child) for name, child in package["deps"].items()}
        if package["path"] != None:
            package["path"] = remap[key]
        packages[remap.get(key, key)] = package
    graph["packages"] = packages

    for root in graph["roots"]:
        root["deps"] = {name: remap.get(child, child) for name, child in root["deps"].items()}

    return graph

def _edges(graph, key):
    return [[name, child] for name, child in graph["packages"][key]["deps"].items()]

def _deps_data(graph, key, reachable):
    # Every transitively reachable package must be configurable: a URL dependency
    # resolves to its sibling spoke (`path` is None); a sub-tree path dependency
    # is configured in-tree (`path` is its location relative to this package).
    # Sub-tree dependencies keep their own `deps`, including any reached through
    # them, so their `build.zig` (e.g. `b.dependency`) and modules resolve.
    packages = {}
    for dep in reachable:
        package = graph["packages"][dep]
        if package["url"] != None:
            path = None
        elif dep.startswith(key + "/"):
            path = dep[len(key) + 1:]
        else:
            fail("Zig package '{}' depends on out-of-tree path dependency '{}', which is unsupported.".format(key, dep))
        packages[dep] = {"deps": _edges(graph, dep), "path": path}
    return {
        "root_deps": _edges(graph, key),
        "packages": packages,
    }

def _zig_packages_impl(module_ctx):
    zig = zig_path(module_ctx)
    zon2json = module_ctx.path(Label("//zig/private:zon2json.zig"))
    cache = zig_cache(module_ctx)
    pkg_dir = module_ctx.path("pkg")

    manifests = []
    manifest_labels = {}
    root_tags = []
    root_dev = False
    root_nondev = False
    for mod in module_ctx.modules:
        for tag in mod.tags.from_file:
            manifest = module_ctx.path(tag.build_zig_zon)

            module_ctx.watch(manifest)
            manifests.append(manifest)
            manifest_labels[str(manifest)] = str(tag.build_zig_zon)
            root_tags.append(tag.build_zig_zon)
            if mod.is_root:
                if module_ctx.is_dev_dependency(tag):
                    root_dev = True
                else:
                    root_nondev = True

    system_libraries = {}
    for mod in module_ctx.modules:
        for tag in mod.tags.system_library:
            existing = system_libraries.get(tag.name)
            if existing != None and existing != tag.lib:
                fail("Conflicting `system_library` annotations for '{}': {} and {}.".format(tag.name, existing, tag.lib))
            system_libraries[tag.name] = tag.lib

    system_integrations = {}
    for mod in module_ctx.modules:
        for tag in mod.tags.system_integration:
            system_integrations[tag.name] = True

    system_integrations = system_integrations.keys()

    error, matrix = collect_configs(module_ctx.modules)
    if error != None:
        fail("Invalid Zig package configuration matrix: {}.".format(error))
    for name in matrix.ignored:
        # buildifier: disable=print
        print("ignoring config/configure tags from non-root module '{}'; set dev_dependency to True to avoid this warning".format(name))

    graph = _resolve_graph(module_ctx, zig, zon2json, cache, pkg_dir, manifests)
    graph = _localize_paths(graph, str(pkg_dir), manifest_labels)

    # `graph["packages"]` is topologically ordered, so each dependency's reachable
    # set is already known by the time we reach a package: accumulate in one pass.
    # Reachability follows every edge (URL and sub-tree path), so URL spokes reached
    # through a sub-tree dependency are configured too.
    reachable = {}
    config_groups = {}
    for key, package in graph["packages"].items():
        reached = {}
        for _name, child in graph["packages"][key]["deps"].items():
            reached[child] = True
            for dep in reachable[child]:
                reached[dep] = True
        reachable[key] = reached
        if package["url"] == None:
            continue

        error, cells = package_cells(key, matrix.cells_by_name, matrix.global_configure, matrix.per_package_configure)
        if error != None:
            fail("Invalid Zig package configuration matrix: {}.".format(error))

        configs = {}
        if cells != None:
            config_settings = {}
            for cell in cells:
                if cell.config_setting != "":
                    config_settings[cell.name] = "@zig_deps//config:cfg_" + cell.name
                    config_groups[cell.name] = {"name": cell.name, "select_on": cell.select_on}
            configs = {
                "configs": json.encode([
                    {"name": cell.name, "zig_options": cell.zig_options, "config_setting": cell.config_setting}
                    for cell in cells
                ]),
                "config_settings": config_settings,
            }

        spokes = [dep for dep in reached if graph["packages"][dep]["url"] != None]
        zig_package(
            name = key,
            url = package["url"],
            zig_hash = key,
            deps = json.encode(_deps_data(graph, key, reached)),
            dep_build_files = {dep: "@{}//:build.zig".format(dep) for dep in spokes},
            system_libraries = system_libraries,
            system_integrations = system_integrations,
            **configs
        )

    manifests, targets = _hub_data(graph, root_tags)
    zig_deps_hub(
        name = "zig_deps",
        manifests = json.encode(manifests),
        packages = targets,
        config_groups = json.encode([config_groups[name] for name in sorted(config_groups)]),
    )

    direct = ["zig_deps"] if root_nondev else []
    dev = ["zig_deps"] if root_dev and not root_nondev else []
    return module_ctx.extension_metadata(
        root_module_direct_deps = direct,
        root_module_direct_dev_deps = dev,
    )

def _hub_data(graph, root_tags):
    """Build the hub manifests and the dependency target map.

    A URL dependency named `name` resolves to the module of the same name in its
    spoke. A local path dependency resolves, by convention, to a target of the
    same name in the dependency manifest's own package, which the user provides.
    Each dependency records whether it is a URL spoke, so the hub can expose its
    other modules by name (`zig_dep(name, module = ...)`).
    """
    tag_by_key = {str(tag): tag for tag in root_tags}
    manifests = []
    targets = {}
    for root, label in zip(graph["roots"], root_tags):
        deps = {}
        for name, key in root["deps"].items():
            url = graph["packages"][key]["url"] != None
            if url:
                target = "@{}//:{}".format(key, name)
                targets[target] = target
            else:
                module = tag_by_key[key].same_package_label(name)
                target = str(module)
                targets[target] = module
            deps[name] = {"target": target, "url": url}
        manifests.append({
            "repo": label.repo_name,
            "package": label.package,
            "scope": str(label.same_package_label("__subpackages__")),
            "deps": deps,
        })
    return manifests, targets

zig_packages = module_extension(
    implementation = _zig_packages_impl,
    tag_classes = {
        "from_file": from_file,
        "system_library": system_library,
        "system_integration": system_integration,
        "config": config,
        "configure": configure,
    },
)
