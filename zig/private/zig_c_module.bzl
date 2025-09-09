"""Implementation of the zig_module rule."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")
load(
    "//zig/private/common:bazel_builtin.bzl",
    BAZEL_BUILTIN_ATTRS = "ATTRS",
)
load("//zig/private/common:data.bzl", "zig_collect_data", "zig_create_runfiles")

load("//zig/private/common:translate_c.bzl", "zig_translate_c")

load("//zig/private/common:zig_cache.bzl", "zig_cache_output")
load("//zig/private/common:zig_lib_dir.bzl", "zig_lib_dir")

DOC = """\
Defines a Zig module.

A Zig module is a collection of Zig sources with a main source file
that defines the module's entry point.

This rule does not perform compilation by itself.
Instead, modules are compiled at the use-site.
Zig performs whole program compilation.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_module")

zig_module(
    name = "my-module",
    main = "main.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":other-module",  # to support `@import("other-module")`.
    ],
)
```
"""

ATTRS = {
    "cdeps": attr.label_list(
        doc = "Other modules required when building the module.",
        mandatory = True,
        providers = [CcInfo],
    ),
    "data": attr.label_list(
        allow_files = True,
        doc = "Files required by the module during runtime.",
        mandatory = False,
    ),
} | BAZEL_BUILTIN_ATTRS

def _zig_c_module_impl(ctx):
    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo

    transitive_data = []
    transitive_runfiles = []

    zig_collect_data(
        data = ctx.attr.data,
        deps = ctx.attr.cdeps,
        transitive_data = transitive_data,
        transitive_runfiles = transitive_runfiles,
    )

    global_args = ctx.actions.args()
    global_args.use_param_file("@%s")

    zig_lib_dir(
        zigtoolchaininfo = zigtoolchaininfo,
        args = global_args,
    )

    zig_cache_output(
        zigtoolchaininfo = zigtoolchaininfo,
        args = global_args,
    )

    default = DefaultInfo(
        runfiles = zig_create_runfiles(
            ctx_runfiles = ctx.runfiles,
            direct_data = [],
            transitive_data = transitive_data,
            transitive_runfiles = transitive_runfiles,
        ),
    )

    cc_infos = [dep[CcInfo] for dep in ctx.attr.cdeps]
    module = zig_translate_c(
        ctx = ctx,
        name = ctx.label.name,
        zigtoolchaininfo = zigtoolchaininfo,
        global_args = global_args,
        cc_infos = cc_infos,
    )

    return [default, module]

zig_c_module = rule(
    _zig_c_module_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = ["//zig:toolchain_type"] + use_cc_toolchain(mandatory = True),
    fragments = ["cpp"],
)
