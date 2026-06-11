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

def _zig_packages_impl(module_ctx):
    zig = zig_path(module_ctx)

    for mod in module_ctx.modules:
        for tag in mod.tags.from_file:
            manifest = module_ctx.path(tag.build_zig_zon)
            result = module_ctx.execute([zig, "version"])

            # buildifier: disable=print
            print("zig {} for manifest {}".format(result.stdout.strip(), manifest))

zig_packages = module_extension(
    implementation = _zig_packages_impl,
    tag_classes = {
        "from_file": from_file,
    },
)
