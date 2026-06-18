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

    graph = _resolve_graph(module_ctx, zig, zon2json, cache, pkg_dir, manifests)
    graph = _localize_paths(graph, str(pkg_dir), manifest_labels)

    # `graph["packages"]` is topologically ordered, so each dependency's reachable
    # set is already known by the time we reach a package: accumulate in one pass.
    # Reachability follows every edge (URL and sub-tree path), so URL spokes reached
    # through a sub-tree dependency are configured too.
    reachable = {}
    for key, package in graph["packages"].items():
        reached = {}
        for _name, child in graph["packages"][key]["deps"].items():
            reached[child] = True
            for dep in reachable[child]:
                reached[dep] = True
        reachable[key] = reached
        if package["url"] != None:
            spokes = [dep for dep in reached if graph["packages"][dep]["url"] != None]
            zig_package(
                name = key,
                url = package["url"],
                zig_hash = key,
                deps = json.encode(_deps_data(graph, key, reached)),
                dep_build_files = {dep: "@{}//:build.zig".format(dep) for dep in spokes},
                system_libraries = system_libraries,
                system_integrations = system_integrations,
            )

    manifests, targets = _hub_data(graph, root_tags)
    zig_deps_hub(
        name = "zig_deps",
        manifests = json.encode(manifests),
        packages = targets,
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
    },
)
