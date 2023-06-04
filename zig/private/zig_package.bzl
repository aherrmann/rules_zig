"""Implementation of the zig_package rule."""

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
        doc = "Other source files required when building the package.",
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
}

def _zig_package_impl(ctx):
    default = DefaultInfo(
    )

    srcs = [ctx.file.main] + ctx.files.srcs
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
