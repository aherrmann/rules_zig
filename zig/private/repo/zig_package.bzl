"""Implementation of the `zig_package` repository rule."""

load("@rules_zig_host_toolchain//:toolchain.bzl", "zig_cache", "zig_path")

DOC = """\
Fetch a Zig package with the Zig SDK.

The Zig SDK downloads, verifies, and prunes the package according to its
`build.zig.zon`, and supports `git+` URLs. Fetching fails if the resulting
package hash does not match the expected `zig_hash`. The package's `build.zig`
is then configured to extract its public module graph (`module_manifest.json`).
"""

ATTRS = {
    "url": attr.string(mandatory = True, doc = "The package URL, e.g. `https://...` or `git+https://...`."),
    "zig_hash": attr.string(mandatory = True, doc = "The expected Zig package hash."),
    "deps": attr.string(
        default = "{\"root_deps\": [], \"packages\": {}}",
        doc = "JSON `{root_deps, packages}` describing the `@dependencies` closure used to configure the package.",
    ),
    "dep_build_files": attr.string_keyed_label_dict(
        doc = "Map from each dependency package hash to its `build.zig`, used to wire `@dependencies`.",
    ),
}

def _package_prefix(repository_ctx, zig, helper, cache, archive):
    # The archive nests the package under `<hash>/<archive-root>/`; strip up to
    # the directory that holds `build.zig.zon`.
    result = repository_ctx.execute(
        [zig, "run", "--cache-dir", cache, "--global-cache-dir", cache, helper, "--", str(archive)],
    )
    if result.return_code != 0:
        fail("Failed to inspect the Zig package archive '{}':\n{}".format(archive, result.stderr))
    return result.stdout.strip()

_EMPTY_DEPS = """\
pub const packages = struct {};
pub const root_deps: []const struct { []const u8, []const u8 } = &.{};
"""

def _zig_string(value):
    return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

def _edge_lines(edges, indent):
    return [
        "{}.{{ {}, {} }},".format(indent, _zig_string(name), _zig_string(key))
        for name, key in edges
    ]

def _build_root(repository_ctx, key, package):
    # A sub-tree path dependency lives inside this package's own tree; a URL
    # dependency lives in its own spoke.
    if package["path"] != None:
        return str(repository_ctx.path(package["path"]))
    return str(repository_ctx.path(repository_ctx.attr.dep_build_files[key]).dirname)

def _build_zig(repository_ctx, key, package):
    if package["path"] != None:
        return str(repository_ctx.path(package["path"] + "/build.zig"))
    return str(repository_ctx.path(repository_ctx.attr.dep_build_files[key]))

def _dependencies_source(repository_ctx, deps):
    """Render the `@dependencies` module that `b.dependency` consumes."""
    packages = deps["packages"]
    if not packages:
        return _EMPTY_DEPS

    lines = ["pub const packages = struct {"]
    for key in sorted(packages):
        package = packages[key]
        lines.append("    pub const @\"{}\" = struct {{".format(key))
        lines.append("        pub const build_root = {};".format(_zig_string(_build_root(repository_ctx, key, package))))
        lines.append("        pub const build_zig = @import(\"{}\");".format(key))
        lines.append("        pub const deps: []const struct { []const u8, []const u8 } = &.{")
        lines.extend(_edge_lines(package["deps"], "            "))
        lines.append("        };")
        lines.append("    };")
    lines.append("};")
    lines.append("")
    lines.append("pub const root_deps: []const struct { []const u8, []const u8 } = &.{")
    lines.extend(_edge_lines(deps["root_deps"], "    "))
    lines.append("};")
    return "\n".join(lines) + "\n"

_FILES = """\
filegroup(
    name = "files",
    srcs = glob(["**"], exclude = ["BUILD.bazel", "module_manifest.json"]),
    visibility = ["//visibility:public"],
)
"""

_ZIG_LIBRARY = """\
zig_library(
    name = "{name}",
    main = "{main}",
    import_name = "{name}",
    srcs = glob(["**/*.zig"], exclude = ["{main}"]),
    deps = {deps},
    visibility = ["//visibility:public"],
)
"""

_ZIG_LIBRARY_SUBTREE = """\
zig_library(
    name = "{name}",
    main = "{main}",
    import_name = "{name}",
    srcs = glob(["{subpath}/**/*.zig"], exclude = ["{main}"]),
    visibility = ["//visibility:public"],
)
"""

def _module_dep(repository_ctx, imported, packages, subtree):
    key = imported["package"]
    if key and key in packages and packages[key]["path"] != None:
        # A sub-tree path dependency is generated as a sibling module in this spoke.
        subtree[imported["name"]] = (packages[key]["path"], imported["root_source"])
        return ":" + imported["name"]
    if key:
        # A cross-package import resolves to the module of the same name in the
        # dependency's spoke.
        spoke = repository_ctx.attr.dep_build_files[key]
        return str(spoke.same_package_label(imported["name"]))
    return ":" + imported["name"]

def _build_file(repository_ctx, modules, packages):
    chunks = ["load(\"@rules_zig//zig:defs.bzl\", \"zig_library\")", "", _FILES]
    subtree = {}
    for module in modules:
        if not module["root_source"]:
            continue
        deps = [_module_dep(repository_ctx, imported, packages, subtree) for imported in module["imports"]]
        chunks.append(_ZIG_LIBRARY.format(
            name = module["name"],
            main = module["root_source"],
            deps = json.encode(deps),
        ))
    for name in sorted(subtree):
        subpath, root_source = subtree[name]
        chunks.append(_ZIG_LIBRARY_SUBTREE.format(
            name = name,
            main = subpath + "/" + root_source,
            subpath = subpath,
        ))
    return "\n".join(chunks)

def _configure(repository_ctx, zig, build_zig, cache):
    """Configure the package's `build.zig` and return its module-graph JSON."""
    configurer = repository_ctx.path(Label("//zig/private:configurer.zig"))
    deps = json.decode(repository_ctx.attr.deps)

    repository_ctx.file("_configure/deps.zig", _dependencies_source(repository_ctx, deps))

    keys = sorted(deps["packages"])

    args = [zig, "build-exe", "--dep", "pkg", "--dep", "deps", "-Mroot=" + str(configurer), "-Mpkg=" + str(build_zig)]
    for key in keys:
        args.extend(["--dep", key])
    args.append("-Mdeps=" + str(repository_ctx.path("_configure/deps.zig")))
    for key in keys:
        args.append("-M{}={}".format(key, _build_zig(repository_ctx, key, deps["packages"][key])))
    args.extend([
        "--cache-dir",
        cache,
        "--global-cache-dir",
        cache,
        "-femit-bin=" + str(repository_ctx.path("_configure/configurer")),
    ])

    compiled = repository_ctx.execute(args)
    if compiled.return_code != 0:
        fail("Failed to compile the Zig configurer for '{}':\n{}".format(repository_ctx.attr.url, compiled.stderr))

    configured = repository_ctx.execute([
        str(repository_ctx.path("_configure/configurer")),
        "--zig",
        str(zig),
        "--build-root",
        str(repository_ctx.path(".")),
    ])
    if configured.return_code != 0:
        fail("Failed to configure the Zig package '{}':\n{}".format(repository_ctx.attr.url, configured.stderr))

    repository_ctx.delete("_configure")
    return configured.stdout

def _zig_package_impl(repository_ctx):
    zig = zig_path(repository_ctx)
    helper = repository_ctx.path(Label("//zig/private:package_prefix.zig"))
    cache = zig_cache(repository_ctx)

    fetch = repository_ctx.execute([zig, "fetch", "--global-cache-dir", cache, repository_ctx.attr.url])
    if fetch.return_code != 0:
        fail("`zig fetch {}` failed:\n{}".format(repository_ctx.attr.url, fetch.stderr))

    fetched_hash = fetch.stdout.strip()
    if fetched_hash != repository_ctx.attr.zig_hash:
        fail("Zig package hash mismatch for '{}':\n  expected: {}\n  fetched:  {}".format(
            repository_ctx.attr.url,
            repository_ctx.attr.zig_hash,
            fetched_hash,
        ))

    archive = repository_ctx.path(cache).get_child("p").get_child(fetched_hash + ".tar.gz")
    repository_ctx.extract(archive, strip_prefix = _package_prefix(repository_ctx, zig, helper, cache, archive))

    build_zig = repository_ctx.path("build.zig")
    modules = []
    if build_zig.exists:
        manifest = _configure(repository_ctx, zig, build_zig, cache)
        repository_ctx.file("module_manifest.json", manifest)
        modules = json.decode(manifest)["modules"]

    packages = json.decode(repository_ctx.attr.deps)["packages"]
    repository_ctx.file("BUILD.bazel", _build_file(repository_ctx, modules, packages))

zig_package = repository_rule(
    _zig_package_impl,
    attrs = ATTRS,
    doc = DOC,
)
