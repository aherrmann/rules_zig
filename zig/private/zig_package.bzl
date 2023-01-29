"""Implementation of the zig_package rule."""

load("//zig/private/providers:zig_package_info.bzl", "ZigPackageInfo")
load("//zig/private:filetypes.bzl", "ZIG_SOURCE_EXTENSIONS")

DOC = """\
"""

ATTRS = {
    "main": attr.label(
        allow_single_file = ZIG_SOURCE_EXTENSIONS,
        doc = "The main source file.",
        mandatory = True,
    ),
    "srcs": attr.label_list(
        allow_files = ZIG_SOURCE_EXTENSIONS,
        doc = "Other source files required when building the package.",
        mandatory = False,
    ),
    "deps": attr.label_list(
        doc = "Other packages required when building the package.",
        mandatory = False,
        providers = [ZigPackageInfo],
    ),
}

def _zig_package_impl(ctx):
    default = DefaultInfo(
    )
    package = ZigPackageInfo(
        name = ctx.label.name,
        main = ctx.file.main,
        srcs = ctx.files.srcs,
    )
    return [default, package]

zig_package = rule(
    _zig_package_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = ["//zig:toolchain_type"],
)
