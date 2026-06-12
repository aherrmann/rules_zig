"""Implementation of the `zig_packages` module extension."""

load("@rules_zig_host_toolchain//:toolchain.bzl", "zig_path")
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

def _fetch(module_ctx, zig, manifest, cache_dir, pkg_dir):
    result = module_ctx.execute(
        [zig, "build", "--fetch=all", "--cache-dir", str(cache_dir), "--pkg-dir", str(pkg_dir)],
        working_directory = str(manifest.dirname),
    )
    if result.return_code != 0:
        fail("`zig build --fetch=all` failed in {}:\n{}".format(manifest.dirname, result.stderr))

def _resolve_graph(module_ctx, zig, zon2json, cache_dir, pkg_dir, manifests):
    result = module_ctx.execute(
        [zig, "run", "--cache-dir", str(cache_dir), zon2json, "--", str(pkg_dir)] +
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

def _url_edges(graph, key):
    return [
        [name, child]
        for name, child in graph["packages"][key]["deps"].items()
        if graph["packages"][child]["url"] != None
    ]

def _deps_data(graph, key, closure):
    return {
        "root_deps": _url_edges(graph, key),
        "packages": {dep: {"has_build_zig": True, "deps": _url_edges(graph, dep)} for dep in closure},
    }

def _zig_packages_impl(module_ctx):
    zig = zig_path(module_ctx)
    zon2json = module_ctx.path(Label("//zig/private:zon2json.zig"))
    cache_dir = module_ctx.path("cache")
    pkg_dir = module_ctx.path("pkg")

    manifests = []
    manifest_labels = {}
    root_tags = []
    root_dev = False
    root_nondev = False
    for mod in module_ctx.modules:
        for tag in mod.tags.from_file:
            manifest = module_ctx.path(tag.build_zig_zon)
            _fetch(module_ctx, zig, manifest, cache_dir, pkg_dir)
            manifests.append(manifest)
            manifest_labels[str(manifest)] = str(tag.build_zig_zon)
            root_tags.append(tag.build_zig_zon)
            if mod.is_root:
                if module_ctx.is_dev_dependency(tag):
                    root_dev = True
                else:
                    root_nondev = True

    graph = _resolve_graph(module_ctx, zig, zon2json, cache_dir, pkg_dir, manifests)
    graph = _localize_paths(graph, str(pkg_dir), manifest_labels)

    # `graph["packages"]` is topologically ordered, so each dependency's closure
    # is already known by the time we reach a package: accumulate in one pass.
    closures = {}
    package_labels = {}
    for key, package in graph["packages"].items():
        closure = {}
        for _name, child in _url_edges(graph, key):
            closure[child] = True
            for dep in closures[child]:
                closure[dep] = True
        closures[key] = closure.keys()
        if package["url"] != None:
            zig_package(
                name = key,
                url = package["url"],
                zig_hash = key,
                deps = json.encode(_deps_data(graph, key, closures[key])),
                dep_build_files = {dep: "@{}//:build.zig".format(dep) for dep in closures[key]},
            )
            package_labels[key] = "@{}//:files".format(key)

    for tag in root_tags:
        package_labels[str(tag)] = tag.same_package_label("files")

    zig_deps_hub(
        name = "zig_deps",
        manifests = json.encode(_hub_manifests(graph, root_tags)),
        packages = package_labels,
    )

    direct = ["zig_deps"] if root_nondev else []
    dev = ["zig_deps"] if root_dev and not root_nondev else []
    return module_ctx.extension_metadata(
        root_module_direct_deps = direct,
        root_module_direct_dev_deps = dev,
    )

def _hub_manifests(graph, root_tags):
    manifests = []
    for root, label in zip(graph["roots"], root_tags):
        manifests.append({
            "repo": label.repo_name,
            "package": label.package,
            "scope": str(label.same_package_label("__subpackages__")),
            "deps": root["deps"],
        })
    return manifests

zig_packages = module_extension(
    implementation = _zig_packages_impl,
    tag_classes = {
        "from_file": from_file,
    },
)
