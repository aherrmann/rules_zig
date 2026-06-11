"""Implementation of the `zig_packages` module extension."""

load("@rules_zig_host_toolchain//:toolchain.bzl", "zig_path")

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

def _zig_packages_impl(module_ctx):
    zig = zig_path(module_ctx)
    zon2json = module_ctx.path(Label("//zig/private:zon2json.zig"))
    cache_dir = module_ctx.path("cache")
    pkg_dir = module_ctx.path("pkg")

    manifests = []
    manifest_labels = {}
    for mod in module_ctx.modules:
        for tag in mod.tags.from_file:
            manifest = module_ctx.path(tag.build_zig_zon)
            _fetch(module_ctx, zig, manifest, cache_dir, pkg_dir)
            manifests.append(manifest)
            manifest_labels[str(manifest)] = str(tag.build_zig_zon)

    graph = _resolve_graph(module_ctx, zig, zon2json, cache_dir, pkg_dir, manifests)
    graph = _localize_paths(graph, str(pkg_dir), manifest_labels)

    # buildifier: disable=print
    print(graph)

zig_packages = module_extension(
    implementation = _zig_packages_impl,
    tag_classes = {
        "from_file": from_file,
    },
)
