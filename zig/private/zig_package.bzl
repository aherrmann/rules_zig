"""Implementation of the zig_package rule."""

load("//zig/private/common:bazel_builtin.bzl", "bazel_builtin_package")
load("//zig/private/common:data.bzl", "zig_collect_data", "zig_create_runfiles")
load("//zig/private/common:filetypes.bzl", "ZIG_SOURCE_EXTENSIONS")
load("//zig/private/providers:zig_package_info.bzl", "ZigPackageInfo")

DOC = """\
Defines a Zig package.

A Zig package is a collection of Zig sources with a main source file
that defines the package's entry point.

This rule does not perform compilation by itself.
Instead, packages are compiled at the use-site.
Zig performs whole program compilation.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_package")

zig_package(
    name = "my-package",
    main = "main.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":other-package",  # to support `@import("other-package")`.
    ],
)
```
"""

ATTRS = {
    "main": attr.label(
        allow_single_file = ZIG_SOURCE_EXTENSIONS,
        doc = "The main source file.",
        mandatory = True,
    ),
    "srcs": attr.label_list(
        allow_files = ZIG_SOURCE_EXTENSIONS,
        doc = "Other Zig source files required when building the package, e.g. files imported using `@import`.",
        mandatory = False,
    ),
    "extra_srcs": attr.label_list(
        allow_files = True,
        doc = "Other files required when building the package, e.g. files embedded using `@embedFile`.",
        mandatory = False,
    ),
    "deps": attr.label_list(
        doc = "Other packages required when building the package.",
        mandatory = False,
        providers = [ZigPackageInfo],
    ),
    "data": attr.label_list(
        allow_files = True,
        doc = "Files required by the package during runtime.",
        mandatory = False,
    ),
}

def _zig_package_impl(ctx):
    transitive_data = []
    transitive_runfiles = []

    zig_collect_data(
        data = ctx.attr.data,
        deps = ctx.attr.deps,
        transitive_data = transitive_data,
        transitive_runfiles = transitive_runfiles,
    )

    default = DefaultInfo(
        runfiles = zig_create_runfiles(
            ctx_runfiles = ctx.runfiles,
            direct_data = [],
            transitive_data = transitive_data,
            transitive_runfiles = transitive_runfiles,
        ),
    )

    srcs = [ctx.file.main] + ctx.files.srcs + ctx.files.extra_srcs
    dep_names = []
    all_mods = []
    all_srcs = []

    bazel_builtin = bazel_builtin_package(ctx)

    packages = [
        dep[ZigPackageInfo]
        for dep in ctx.attr.deps
        if ZigPackageInfo in dep
    ] + [bazel_builtin]

    for package in packages:
        if package.canonical_name != package.name:
            dep_names.append("{}={}".format(package.name, package.canonical_name))
        else:
            dep_names.append(package.name)
        all_mods.append(package.all_mods)
        all_srcs.append(package.all_srcs)

    package = ZigPackageInfo(
        name = ctx.label.name,
        canonical_name = ctx.label.name,
        main = ctx.file.main,
        srcs = ctx.files.srcs,
        all_mods = depset(
            direct = ["{name}:{deps}:{src}".format(
                name = ctx.label.name,
                deps = ",".join(dep_names),
                src = ctx.file.main.path,
            )],
            transitive = all_mods,
        ),
        all_srcs = depset(
            direct = srcs,
            transitive = all_srcs,
        ),
    )

    return [default, package]

zig_package = rule(
    _zig_package_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = ["//zig:toolchain_type"],
)
