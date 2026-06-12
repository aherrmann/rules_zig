"""Implementation of the `zig_package` repository rule."""

load("@rules_zig_host_toolchain//:toolchain.bzl", "zig_path")

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
    result = repository_ctx.execute([zig, "run", "--cache-dir", str(cache), helper, "--", str(archive)])
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

def _dependencies_source(repository_ctx, deps):
    """Render the `@dependencies` module that `b.dependency` consumes."""
    packages = deps["packages"]
    if not packages:
        return _EMPTY_DEPS

    build_files = repository_ctx.attr.dep_build_files
    lines = ["pub const packages = struct {"]
    for key in sorted(packages):
        package = packages[key]
        build_root = str(repository_ctx.path(build_files[key]).dirname)
        lines.append("    pub const @\"{}\" = struct {{".format(key))
        lines.append("        pub const build_root = {};".format(_zig_string(build_root)))
        if package["has_build_zig"]:
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

def _configure(repository_ctx, zig, build_zig):
    """Configure the package's `build.zig` and return its module-graph JSON."""
    configurer = repository_ctx.path(Label("//zig/private:configurer.zig"))
    deps = json.decode(repository_ctx.attr.deps)
    build_files = repository_ctx.attr.dep_build_files

    repository_ctx.file("_configure/deps.zig", _dependencies_source(repository_ctx, deps))

    hashes = sorted([key for key in deps["packages"] if deps["packages"][key]["has_build_zig"]])

    args = [zig, "build-exe", "--dep", "pkg", "--dep", "deps", "-Mroot=" + str(configurer), "-Mpkg=" + str(build_zig)]
    for key in hashes:
        args.extend(["--dep", key])
    args.append("-Mdeps=" + str(repository_ctx.path("_configure/deps.zig")))
    for key in hashes:
        args.append("-M{}={}".format(key, repository_ctx.path(build_files[key])))
    args.extend([
        "--cache-dir",
        str(repository_ctx.path("_configure/cache")),
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
    cache = repository_ctx.path("cache")

    fetch = repository_ctx.execute([zig, "fetch", "--global-cache-dir", str(cache), repository_ctx.attr.url])
    if fetch.return_code != 0:
        fail("`zig fetch {}` failed:\n{}".format(repository_ctx.attr.url, fetch.stderr))

    fetched_hash = fetch.stdout.strip()
    if fetched_hash != repository_ctx.attr.zig_hash:
        fail("Zig package hash mismatch for '{}':\n  expected: {}\n  fetched:  {}".format(
            repository_ctx.attr.url,
            repository_ctx.attr.zig_hash,
            fetched_hash,
        ))

    archive = cache.get_child("p").get_child(fetched_hash + ".tar.gz")
    repository_ctx.extract(archive, strip_prefix = _package_prefix(repository_ctx, zig, helper, cache, archive))
    repository_ctx.delete(cache)

    build_zig = repository_ctx.path("build.zig")
    if build_zig.exists:
        repository_ctx.file("module_manifest.json", _configure(repository_ctx, zig, build_zig))

    repository_ctx.file("BUILD.bazel", """\
filegroup(
    name = "files",
    srcs = glob(["**"], exclude = ["BUILD.bazel", "module_manifest.json"]),
    visibility = ["//visibility:public"],
)
""")

zig_package = repository_rule(
    _zig_package_impl,
    attrs = ATTRS,
    doc = DOC,
)
