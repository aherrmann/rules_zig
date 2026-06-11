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

def _zig_build(module_ctx, zig, project_dir, cache_dir, pkg_dir, args):
    result = module_ctx.execute(
        [zig, "build", "--cache-dir", str(cache_dir), "--pkg-dir", str(pkg_dir)] + args,
        working_directory = str(project_dir),
    )
    if result.return_code != 0:
        fail("`zig build {}` failed in {}:\n{}".format(" ".join(args), project_dir, result.stderr))

def _read_dependencies(module_ctx, zig, manifest):
    project_dir = manifest.dirname
    cache_dir = module_ctx.path("cache")
    pkg_dir = module_ctx.path("pkg")

    _zig_build(module_ctx, zig, project_dir, cache_dir, pkg_dir, ["--fetch=all"])
    _zig_build(module_ctx, zig, project_dir, cache_dir, pkg_dir, ["--list-steps"])

    output_dir = cache_dir.get_child("o")
    for entry in output_dir.readdir():
        dependencies = entry.get_child("dependencies.zig")
        if dependencies.exists:
            return module_ctx.read(dependencies)

    fail("Could not find the generated `@dependencies` module under {}.".format(output_dir))

def _zig_packages_impl(module_ctx):
    zig = zig_path(module_ctx)

    for mod in module_ctx.modules:
        for tag in mod.tags.from_file:
            manifest = module_ctx.path(tag.build_zig_zon)
            dependencies = _read_dependencies(module_ctx, zig, manifest)

            # buildifier: disable=print
            print(dependencies)

zig_packages = module_extension(
    implementation = _zig_packages_impl,
    tag_classes = {
        "from_file": from_file,
    },
)
