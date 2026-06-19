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
    "system_libraries": attr.string_keyed_label_dict(
        doc = "Map from a system-library name (as passed to `linkSystemLibrary`) to a `cc_library` providing it.",
    ),
    "system_integrations": attr.string_list(
        doc = "Names of optional system integrations (`systemIntegrationOption`) to enable when configuring the package.",
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
    import_names = {import_names},
    visibility = ["//visibility:public"],
)
"""

_ZIG_LIBRARY_SUBTREE = """\
zig_library(
    name = "{name}",
    main = "{main}",
    import_name = "{import_name}",
    srcs = glob(["{subpath}/**/*.zig"], exclude = ["{main}"]),
    deps = {deps},
    import_names = {import_names},
    visibility = ["//visibility:public"],
)
"""

_HEADER_EXTENSIONS = ["h", "hh", "hpp", "hxx"]

# vendored C is compiled via sibling `cc_library` targets.
_CC_LIBRARY = """\
cc_library(
    name = "{name}",
    srcs = {srcs},
    hdrs = glob({hdrs}, allow_empty = True),
    copts = {copts},
    includes = {includes},
    visibility = ["//visibility:public"],
)
"""

_CC_LIBRARY_GROUP = """\
cc_library(
    name = "{name}",
    deps = {deps},
    visibility = ["//visibility:public"],
)
"""

def parse_cells(configs):
    """Parse the `configs` attr into the package's configuration matrix cells.

    Args:
      configs: the JSON `configs` attr, or "" for the host default.

    Returns:
      (error, cells), each cell `struct(name, zig_options, config_setting)`.
    """
    if not configs:
        return (None, [struct(name = "", zig_options = [], config_setting = "")])

    cells = [
        struct(name = cell["name"], zig_options = cell["zig_options"], config_setting = cell["config_setting"])
        for cell in json.decode(configs)
    ]
    fallbacks = [cell for cell in cells if cell.config_setting == ""]
    if len(fallbacks) != 1:
        return ("expected exactly one fallback cell, found {}".format(len(fallbacks)), None)

    rest = [cell for cell in cells if cell.config_setting != ""]
    return (None, fallbacks + rest)

def merge(package, per_cell_data, cells):
    """Merge each cell's target records into one set, pushing `select()` to attrs.

    The set of target names must agree across cells, as must each target's `kind`
    and its `fixed` attrs. Each `varying` attr resolves to `("const", value)` when
    equal across cells, else `("select", {cell: value})`.

    Args:
      package: the package URL, for error messages.
      per_cell_data: map from cell name to that cell's list of target records.
      cells: the ordered cells, the fallback first.

    Returns:
      (error, merged), each merged record a `struct(kind, name, fixed, varying)`,
        fallback first.
    """
    fallback = cells[0].name

    indexed = {
        cell.name: {record.name: record for record in per_cell_data[cell.name]}
        for cell in cells
    }

    base_names = sorted(indexed[fallback])
    for cell in cells[1:]:
        if sorted(indexed[cell.name]) != base_names:
            return ("package '{}' produces a different set of targets under config '{}' than under '{}'".format(
                package,
                cell.name,
                fallback,
            ), None)

    merged = []
    for name in indexed[fallback]:
        base = indexed[fallback][name]

        for cell in cells[1:]:
            other = indexed[cell.name][name]
            if other.kind != base.kind:
                return ("package '{}' target '{}' has kind '{}' under config '{}' but '{}' under '{}'".format(
                    package,
                    name,
                    other.kind,
                    cell.name,
                    base.kind,
                    fallback,
                ), None)
            for attr in base.fixed:
                if base.fixed[attr] != other.fixed[attr]:
                    return ("package '{}' target '{}' fixed attribute '{}' varies by configuration".format(
                        package,
                        base.name,
                        attr,
                    ), None)

        resolved = {}
        for attr in base.varying:
            value = base.varying[attr]
            uniform = all([indexed[cell.name][name].varying[attr] == value for cell in cells[1:]])
            if uniform:
                resolved[attr] = ("const", value)
            else:
                resolved[attr] = ("select", {cell.name: indexed[cell.name][name].varying[attr] for cell in cells})

        merged.append(struct(kind = base.kind, name = base.name, fixed = base.fixed, varying = resolved))

    return (None, merged)

def render_attr(config_settings, resolved, cells):
    """Render a merged attribute as a literal or a `select()`.

    Args:
      config_settings: map from a non-fallback cell name to its config_setting label.
      resolved: `("const", value)` or `("select", {cell: value})`.
      cells: configuration matrix cells.

    Returns:
      the attribute's Starlark code.
    """
    if resolved[0] == "const":
        return json.encode(resolved[1])

    by_cell = resolved[1]
    lines = ["select({"]
    for cell in cells:
        if cell.config_setting != "":
            lines.append("    {}: {},".format(json.encode(config_settings[cell.name]), json.encode(by_cell[cell.name])))
    for cell in cells:
        if cell.config_setting == "":
            lines.append("    {}: {},".format(json.encode("//conditions:default"), json.encode(by_cell[cell.name])))
    lines.append("})")
    return "\n".join(lines)

def render(config_settings, merged, cells):
    """Render merged target records into the spoke's `BUILD.bazel` text.

    Args:
      config_settings: map from a non-fallback cell name to its config_setting label.
      merged: the merged target records from `merge`.
      cells: configuration matrix cells.

    Returns:
      the `BUILD.bazel` contents.
    """
    cc_chunks = []
    library_chunks = []
    has_cc = False
    for record in merged:
        fixed = record.fixed
        varying = record.varying
        if record.kind == "zig_library":
            library_chunks.append(_ZIG_LIBRARY.format(
                name = record.name,
                main = fixed["main"],
                deps = render_attr(config_settings, varying["deps"], cells),
                import_names = render_attr(config_settings, varying["import_names"], cells),
            ))
        elif record.kind == "zig_library_subtree":
            library_chunks.append(_ZIG_LIBRARY_SUBTREE.format(
                name = record.name,
                import_name = fixed["import_name"],
                main = fixed["main"],
                subpath = fixed["subpath"],
                deps = render_attr(config_settings, varying["deps"], cells),
                import_names = render_attr(config_settings, varying["import_names"], cells),
            ))
        elif record.kind == "cc_library":
            has_cc = True
            cc_chunks.append(_CC_LIBRARY.format(
                name = record.name,
                srcs = render_attr(config_settings, varying["srcs"], cells),
                hdrs = json.encode(fixed["header_globs"]),
                copts = render_attr(config_settings, varying["copts"], cells),
                includes = render_attr(config_settings, varying["includes"], cells),
            ))
        elif record.kind == "cc_library_group":
            has_cc = True
            cc_chunks.append(_CC_LIBRARY_GROUP.format(
                name = record.name,
                deps = render_attr(config_settings, varying["deps"], cells),
            ))

    loads = ["load(\"@rules_zig//zig:defs.bzl\", \"zig_library\")"]
    if has_cc:
        loads.append("load(\"@rules_cc//cc:defs.bzl\", \"cc_library\")")
    return "\n".join(loads + ["", _FILES] + cc_chunks + library_chunks)

def _is_subtree(packages, owner):
    return bool(owner) and owner in packages and packages[owner]["path"] != None

def _target_name(packages, owner, module):
    # Root-package modules keep their bare name (the spoke's public API). In-tree
    # sub-tree modules are namespaced by their sub-path so that identically named
    # modules in different sub-trees do not collide. Targets are keyed by the
    # module's own name, independent of the (possibly aliased) name it is imported
    # under.
    if not owner:
        return module
    return packages[owner]["path"] + "/" + module

def _csrc_path(packages, owner, path):
    if not owner:
        return path
    return packages[owner]["path"] + "/" + path

def _module_dep(repository_ctx, imported, packages):
    key = imported["package"]
    if _is_subtree(packages, key):
        # An in-tree (sub-tree) module is generated as a sibling in this spoke.
        return ":" + _target_name(packages, key, imported["module"])
    if key:
        # A cross-package import resolves to the module in the dependency's spoke.
        spoke = repository_ctx.attr.dep_build_files[key]
        return str(spoke.same_package_label(imported["module"]))
    return ":" + imported["module"]

def _build_file(repository_ctx, modules, packages):
    library_chunks = []
    cc_chunks = []
    for module in modules:
        if not module["root_source"]:
            continue

        # The configurer reports every reachable module tagged with its owner: the
        # root package being configured (empty key) becomes a top-level library; an
        # in-tree sub-tree path dependency becomes a library scoped to its sub-path;
        # a module owned by a URL dependency lives in its own spoke and is skipped.
        owner = module["package"]
        if owner and not _is_subtree(packages, owner):
            continue

        unsupported = module.get("unsupported")
        if unsupported:
            fail(("The Zig package '{}' module '{}' uses unsupported constructs: {}.").format(
                repository_ctx.attr.url,
                module["name"],
                "; ".join(unsupported),
            ))

        # A dependency is imported under its own name by default; an import that
        # uses a different name is remapped per-edge via `import_names`, so the
        # same module can be imported under different names by different modules.
        deps = []
        import_names = {}
        for imported in module["imports"]:
            target = _module_dep(repository_ctx, imported, packages)
            deps.append(target)
            if imported["name"] != imported["module"]:
                import_names[target] = imported["name"]

        if module.get("link_libc"):
            deps.append("@rules_zig//zig/lib:libc")
        if module.get("link_libcpp"):
            deps.append("@rules_zig//zig/lib:libc++")

        for name in module.get("system_libs", []):
            lib = repository_ctx.attr.system_libraries.get(name)
            if lib == None:
                fail(("The Zig package '{}' module '{}' requires the system library '{}', " +
                      "which is not provided. Map it to a cc_library with a " +
                      "`zig_packages.system_library(name = \"{}\", lib = ...)` annotation.").format(
                    repository_ctx.attr.url,
                    module["name"],
                    name,
                    name,
                ))
            deps.append(str(lib))

        c_sources = []
        for csrc in module.get("csrcs", []):
            if csrc["language"] not in (None, "c", "cpp"):
                fail(("The Zig package '{}' module '{}' declares the unsupported language '{}' for a C source.").format(
                    repository_ctx.attr.url,
                    module["name"],
                    csrc["language"],
                ))
            c_sources.append((_csrc_path(packages, owner, csrc["path"]), csrc["flags"]))

        if c_sources:
            cinc = _target_name(packages, owner, module["name"]) + ".cinc"
            prefix = (packages[owner]["path"] + "/") if owner else ""

            header_dirs = {prefix + inc["path"]: None for inc in module.get("include_dirs", [])}
            for path, _flags in c_sources:
                header_dirs[path.rpartition("/")[0]] = None
            header_globs = [
                (dir + "/" if dir else "") + "**/*." + ext
                for dir in sorted(header_dirs)
                for ext in _HEADER_EXTENSIONS
            ]
            includes = [prefix + inc["path"] for inc in module.get("include_dirs", [])]

            # Partition C sources by common `copts`.
            groups = []
            for path, flags in c_sources:
                if groups and groups[-1][0] == flags:
                    groups[-1][1].append(path)
                else:
                    groups.append((flags, [path]))

            group_labels = []
            for index in range(len(groups)):
                flags = groups[index][0]
                paths = groups[index][1]
                group_name = "{}.{}".format(cinc, index)
                group_labels.append(":" + group_name)
                cc_chunks.append(_CC_LIBRARY.format(
                    name = group_name,
                    srcs = json.encode(paths),
                    hdrs = json.encode(header_globs),
                    copts = json.encode(flags),
                    includes = json.encode(includes),
                ))
            cc_chunks.append(_CC_LIBRARY_GROUP.format(
                name = cinc,
                deps = json.encode(group_labels),
            ))
            deps.append(":" + cinc)

        if not owner:
            library_chunks.append(_ZIG_LIBRARY.format(
                name = module["name"],
                main = module["root_source"],
                deps = json.encode(deps),
                import_names = json.encode(import_names),
            ))
        else:
            subpath = packages[owner]["path"]
            library_chunks.append(_ZIG_LIBRARY_SUBTREE.format(
                name = _target_name(packages, owner, module["name"]),
                import_name = module["name"],
                main = subpath + "/" + module["root_source"],
                subpath = subpath,
                deps = json.encode(deps),
                import_names = json.encode(import_names),
            ))

    loads = ["load(\"@rules_zig//zig:defs.bzl\", \"zig_library\")"]
    if cc_chunks:
        loads.append("load(\"@rules_cc//cc:defs.bzl\", \"cc_library\")")
    return "\n".join(loads + ["", _FILES] + cc_chunks + library_chunks)

def _configure(repository_ctx, zig, build_zig, cache):
    """Configure the package's `build.zig` and return its module-graph JSON."""
    configurer = repository_ctx.path(Label("//zig/private:configurer.zig"))
    deps = json.decode(repository_ctx.attr.deps)

    for key in sorted(deps["packages"]):
        package = deps["packages"][key]
        if package["path"] != None and not repository_ctx.path(package["path"] + "/build.zig").exists:
            fail(("The Zig package '{}' has a source-only dependency at '{}' (a " +
                  "`build.zig.zon` with no `build.zig`); source-only dependencies " +
                  "are not supported.").format(repository_ctx.attr.url, package["path"]))

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

    configure_args = [
        str(repository_ctx.path("_configure/configurer")),
        "--zig",
        str(zig),
        "--build-root",
        str(repository_ctx.path(".")),
    ]
    for name in repository_ctx.attr.system_integrations:
        configure_args.extend(["--system-integration", name])
    configured = repository_ctx.execute(configure_args)
    if configured.return_code != 0:
        fail("Failed to configure the Zig package '{}':\n{}".format(repository_ctx.attr.url, configured.stderr))

    repository_ctx.delete("_configure")
    return configured.stdout

def _materialize_generated(repository_ctx, modules, packages):
    for module in modules:
        generated = module.get("generated_source")
        if generated == None:
            continue
        rel = "_zig_generated/" + module["name"] + ".zig"
        if _is_subtree(packages, module["package"]):
            repository_ctx.file(packages[module["package"]]["path"] + "/" + rel, generated)
        else:
            repository_ctx.file(rel, generated)
        module["root_source"] = rel

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
    _materialize_generated(repository_ctx, modules, packages)
    repository_ctx.file("BUILD.bazel", _build_file(repository_ctx, modules, packages))

zig_package = repository_rule(
    _zig_package_impl,
    attrs = ATTRS,
    doc = DOC,
)
