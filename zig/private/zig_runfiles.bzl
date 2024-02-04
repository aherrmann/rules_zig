"""Implementation of the zig_runfiles rule."""

load("//zig/private/common:data.bzl", "zig_collect_data", "zig_create_runfiles")
load("//zig/private/providers:zig_package_info.bzl", "ZigPackageInfo")

DOC = """\
Defines a Zig runfiles collection.

That is a collection of data files that are runtime dependencies and a Zig
source module to support access to these data files at runtime.

This rule does not perform compilation by itself.
Instead, packages are compiled at the use-site.
Zig performs whole program compilation.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_runfiles")

zig_runfiles(
    name = "my-runfiles",
    data = [
        ":data.txt",
        "@dependency//more:data.txt",
    ],
)
```
"""

ATTRS = {
    "data": attr.label_list(
        allow_files = True,
        doc = "Files required by the package during runtime.",
        mandatory = False,
    ),
}

def _zig_runfiles_impl(ctx):
    transitive_data = []
    transitive_runfiles = []

    zig_collect_data(
        data = ctx.attr.data,
        deps = [],
        transitive_data = transitive_data,
        transitive_runfiles = transitive_runfiles,
    )

    main = ctx.actions.declare_file(ctx.label.name + ".zig")
    repo_name = ctx.label.repo_name if hasattr(ctx.label, "repo_name") else ctx.label.workspace_name

    # TODO[AH] Generate entries for the data files.
    content = 'pub const current_repository = "{}";'.format(repo_name)
    ctx.actions.write(main, content, is_executable = False)

    default = DefaultInfo(
        runfiles = zig_create_runfiles(
            ctx_runfiles = ctx.runfiles,
            direct_data = [],
            transitive_data = transitive_data,
            transitive_runfiles = transitive_runfiles,
        ),
    )

    srcs = [main]

    # TODO[AH] Factor out the package creation logic.
    package = ZigPackageInfo(
        name = ctx.label.name,
        canonical_name = ctx.label.name,
        main = main,
        all_mods = depset(
            direct = ["{name}:{deps}:{src}".format(
                name = ctx.label.name,
                # TODO[AH] Depend on the runfiles library.
                deps = "",
                src = main.path,
            )],
            transitive = [],
        ),
        all_srcs = depset(
            direct = srcs,
            transitive = [],
        ),
    )

    return [default, package]

zig_runfiles = rule(
    _zig_runfiles_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = ["//zig:toolchain_type"],
)
