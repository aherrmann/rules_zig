"""Zig documentation generation."""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//zig/private:cc_helper.bzl", "need_translate_c")
load(
    "//zig/private/common:bazel_builtin.bzl",
    "bazel_builtin_module",
)
load("//zig/private/common:csrcs.bzl", "zig_csrcs")
load("//zig/private/common:location_expansion.bzl", "location_expansion")
load("//zig/private/common:translate_c.bzl", "zig_translate_c")
load("//zig/private/common:zig_cache.bzl", "zig_cache_output")
load("//zig/private/common:zig_lib_dir.bzl", "zig_lib_dir")
load(
    "//zig/private/providers:zig_module_info.bzl",
    "ZigModuleInfo",
    "zig_module_info",
    "zig_module_specifications",
)
load(
    "//zig/private/providers:zig_settings_info.bzl",
    "ZigSettingsInfo",
    "zig_settings",
)
load(
    "//zig/private/providers:zig_target_info.bzl",
    "zig_target_platform",
)

ATTRS = {
    "extra_docs": attr.label_list(
        allow_files = True,
        doc = "Other files required to generate documentation, e.g. guides referenced using `//!zig-autodoc-guide:`.",
        mandatory = False,
    ),
}

def zig_docs_impl(ctx, *, kind):
    """Common implementation of Zig documentation generation.

    Args:
      ctx: Bazel rule context object.
      kind: String; The kind of the rule, one of `zig_binary`, `zig_static_library`, `zig_shared_library`, `zig_test`.

    Returns:
      List of providers.
    """
    root_module_is_only_dep = len(ctx.attr.deps) == 1 and ZigModuleInfo in ctx.attr.deps[0] and ctx.attr.main == None
    if root_module_is_only_dep:
        if len(ctx.attr.srcs) > 0:
            fail("'srcs' cannot be set without a 'main'. They are taken from the root module defined by the single zig dependency.")
        if len(ctx.attr.extra_srcs) > 0:
            fail("'extra_srcs' cannot be set without a 'main'. They are taken from the root module defined by the single zig dependency.")
        if len(ctx.attr.csrcs) > 0:
            fail("'csrcs' cannot be set without a 'main'. They are taken from the root module defined by the single zig dependency.")

    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo
    zigtargetinfo = ctx.toolchains["//zig/target:toolchain_type"].zigtargetinfo

    files = None

    outputs = []

    direct_inputs = []
    transitive_inputs = []

    args = ctx.actions.args()
    args.use_param_file("@%s")

    global_args = ctx.actions.args()
    global_args.use_param_file("@%s")

    output = ctx.actions.declare_directory(ctx.label.name + ".docs")
    outputs.append(output)
    args.add(output.path, format = "-femit-docs=%s")
    args.add("-fno-emit-bin")
    args.add("-fno-emit-implib")

    files = depset([output])

    zig_lib_dir(
        zigtoolchaininfo = zigtoolchaininfo,
        args = global_args,
    )

    zig_cache_output(
        zigtoolchaininfo = zigtoolchaininfo,
        args = global_args,
    )

    location_targets = ctx.attr.data

    copts = location_expansion(
        ctx = ctx,
        targets = location_targets,
        outputs = outputs,
        attribute_name = "copts",
        strings = ctx.attr.copts,
    )

    zig_csrcs(
        copts = copts,
        csrcs = ctx.files.csrcs,
        inputs = direct_inputs,
        args = args,
    )

    direct_inputs.extend(ctx.files.extra_docs)

    cdeps = []
    if ctx.attr.cdeps:
        # buildifier: disable=print
        print("""\
The `cdeps` attribute of `zig_build` is deprecated, use `deps` instead.
""")
        cdeps = [dep[CcInfo] for dep in ctx.attr.cdeps]

    zdeps = []
    for dep in ctx.attr.deps:
        if ZigModuleInfo in dep:
            zdeps.append(dep[ZigModuleInfo])
        elif CcInfo in dep:
            cdeps.append(dep[CcInfo])

    if root_module_is_only_dep:
        root_module = ctx.attr.deps[0][ZigModuleInfo]
    else:
        root_module = zig_module_info(
            name = ctx.attr.name,
            canonical_name = ctx.label.name,
            main = ctx.file.main,
            srcs = ctx.files.srcs,
            extra_srcs = ctx.files.extra_srcs,
            deps = zdeps + [bazel_builtin_module(ctx)],
            cdeps = cdeps,
        )

    zig_settings(
        settings = ctx.attr._settings[ZigSettingsInfo],
        args = args,
    )

    zig_target_platform(
        target = zigtargetinfo,
        args = args,
    )

    c_module = None
    if need_translate_c(root_module.cc_info):
        c_module = zig_translate_c(
            ctx = ctx,
            name = "c",
            zigtoolchaininfo = zigtoolchaininfo,
            global_args = global_args,
            cc_infos = [root_module.cc_info],
            output_prefix = "docs",
        )
        transitive_inputs.append(c_module.transitive_inputs)

    zig_module_specifications(
        root_module = root_module,
        args = args,
        c_module = c_module,
    )

    transitive_inputs.append(root_module.transitive_inputs)

    inputs = depset(
        direct = direct_inputs,
        transitive = transitive_inputs,
        order = "preorder",
    )

    if kind == "zig_binary":
        command = ["build-exe"]
    elif kind == "zig_test":
        command = ["test", "--test-no-exec"]
    elif kind == "zig_static_library":
        command = ["build-lib"]
    elif kind == "zig_shared_library":
        command = ["build-lib", "-dynamic"]
    else:
        fail("Unknown rule kind '{}'.".format(kind))

    arguments = command + [global_args] + [args]
    mnemonic = "ZigBuildDocs"
    progress_message = "Generating Zig documentation for %{input} in %{output}"

    ctx.actions.run(
        outputs = outputs,
        inputs = inputs,
        executable = zigtoolchaininfo.zig_exe_path,
        tools = zigtoolchaininfo.zig_files,
        arguments = arguments,
        mnemonic = mnemonic,
        progress_message = progress_message,
        execution_requirements = {tag: "" for tag in ctx.attr.tags},
    )

    providers = []

    output_groups = dict(
        zig_docs = files,
    )

    return providers, output_groups
