"""Implementation of the zig_package rule."""

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
        doc = """\
Other packages required when building the package.

Note, the Zig compiler requires that every package dependency is specified with
its own package dependencies on the command-line, recursively. Meaning the
entire Zig package dependency tree will be represented on the command-line
without deduplication of shared nodes. Keep this in mind when you defined the
granularity of your Zig packages.
""",
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
    flags = ["--pkg-begin", ctx.label.name, ctx.file.main.path]
    all_srcs = []

    for dep in ctx.attr.deps:
        if ZigPackageInfo in dep:
            package = dep[ZigPackageInfo]
            flags.extend(package.flags)
            all_srcs.append(package.all_srcs)

    flags.append("--pkg-end")

    package = ZigPackageInfo(
        name = ctx.label.name,
        main = ctx.file.main,
        srcs = ctx.files.srcs,
        flags = flags,
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
