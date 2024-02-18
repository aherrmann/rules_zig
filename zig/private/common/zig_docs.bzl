"""Zig documentation generation."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    "//zig/private/common:bazel_builtin.bzl",
    "bazel_builtin_module",
)
load("//zig/private/common:cdeps.bzl", "zig_cdeps")
load("//zig/private/common:csrcs.bzl", "zig_csrcs")
load("//zig/private/common:location_expansion.bzl", "location_expansion")
load("//zig/private/common:zig_cache.bzl", "zig_cache_output")
load("//zig/private/common:zig_lib_dir.bzl", "zig_lib_dir")
load(
    "//zig/private/providers:zig_module_info.bzl",
    "zig_module_dependencies",
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
      kind: String; The kind of the rule, one of `zig_binary`, `zig_library`, `zig_shared_library`, `zig_test`.

    Returns:
      List of providers.
    """
    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo
    zigtargetinfo = ctx.toolchains["//zig/target:toolchain_type"].zigtargetinfo

    files = None
    direct_data = []

    outputs = []

    direct_inputs = []
    transitive_inputs = []

    args = ctx.actions.args()
    args.use_param_file("@%s")

    output = ctx.actions.declare_directory(ctx.label.name + ".docs")
    outputs.append(output)
    args.add(output.path, format = "-femit-docs=%s")
    args.add("-fno-emit-bin")
    args.add("-fno-emit-implib")

    files = depset([output])

    direct_inputs.append(ctx.file.main)
    direct_inputs.extend(ctx.files.srcs)
    direct_inputs.extend(ctx.files.extra_srcs)
    direct_inputs.extend(ctx.files.extra_docs)

    if zigtoolchaininfo.zig_version.startswith("0.11"):
        args.add_all(["--main-pkg-path", "."])
    args.add(ctx.file.main)

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

    bazel_builtin = bazel_builtin_module(ctx)

    zig_module_dependencies(
        deps = ctx.attr.deps,
        extra_deps = [bazel_builtin],
        inputs = transitive_inputs,
        args = args,
    )

    zig_cdeps(
        cdeps = ctx.attr.cdeps,
        output_dir = paths.join(ctx.bin_dir.path, ctx.label.package),
        os = zigtargetinfo.triple.os,
        direct_inputs = direct_inputs,
        transitive_inputs = transitive_inputs,
        args = args,
        data = direct_data,
    )

    zig_lib_dir(
        zigtoolchaininfo = zigtoolchaininfo,
        args = args,
    )

    zig_cache_output(
        zigtoolchaininfo = zigtoolchaininfo,
        args = args,
    )

    zig_settings(
        settings = ctx.attr._settings[ZigSettingsInfo],
        args = args,
    )

    zig_target_platform(
        target = zigtargetinfo,
        args = args,
    )

    inputs = depset(
        direct = direct_inputs,
        transitive = transitive_inputs,
        order = "preorder",
    )

    if kind == "zig_binary":
        command = ["build-exe"]
    elif kind == "zig_test":
        command = ["test", "--test-no-exec"]
    elif kind == "zig_library":
        command = ["build-lib"]
    elif kind == "zig_shared_library":
        command = ["build-lib", "-dynamic"]
    else:
        fail("Unknown rule kind '{}'.".format(kind))

    arguments = command + [args]
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

    output_group = OutputGroupInfo(
        zig_docs = files,
    )
    providers.append(output_group)

    return providers
