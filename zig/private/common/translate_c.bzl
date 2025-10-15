"""Handle translate-c pass."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//zig/private/providers:zig_module_info.bzl", "zig_module_info")

def zig_translate_c(*, ctx, name, zigtoolchaininfo, global_args, cc_infos, output_prefix = ""):
    """Handle translate-c build action.

    Sets the appropriate command-line flags for the Zig compiler to expose
    provided headers and link against the provided libraries.

    Args:
      ctx: Context object.
      name: String, the name of the resulting Zig module.
      zigtoolchaininfo: ZigToolchainInfo.
      global_args: Args; mutable, Append the global Zig command-line flags to this object.
      cc_infos: List of CcInfo, The CcInfo providers for the C dependencies.
      output_prefix: String, a prefix to be used for generated files. Used for zig_docs.

    Returns:
        `ZigModuleInfo` surrounding the generated zig file.
    """
    cc_info = cc_common.merge_cc_infos(direct_cc_infos = cc_infos)
    compilation_context = cc_info.compilation_context
    linking_context = cc_info.linking_context

    inputs = []
    transitive_inputs = [compilation_context.headers]

    hdr = ctx.actions.declare_file("{}{}_c.h".format(output_prefix, ctx.label.name))
    ctx.actions.write(hdr, "\n".join([
        '#include "{}"'.format(hdr.path)
        for hdr in compilation_context.direct_public_headers
    ]))
    inputs.append(hdr)

    args = ctx.actions.args()
    args.add(hdr)
    args.add("-lc")
    args.add_all(compilation_context.defines, format_each = "-D%s")
    args.add("-I.")
    args.add_all(compilation_context.includes, format_each = "-I%s")

    # Note, Zig does not support `-iquote` as of Zig 0.12.0
    # args.add_all(compilation_context.quote_includes, format_each = "-iquote%s")
    args.add_all(compilation_context.quote_includes, format_each = "-I%s")
    args.add_all(compilation_context.system_includes, before_each = "-isystem")

    # Added in Bazel 7, see https://github.com/bazelbuild/bazel/commit/a6ef0b341a8ffe8ab27e5ace79d8eaae158c422b
    args.add_all(getattr(compilation_context, "external_includes", []), before_each = "-isystem")
    args.add_all(compilation_context.framework_includes, format_each = "-F%s")

    # If there is a CC toolchain, add builtin directories
    # This allows including to extra headers provided directly by the toolchain.
    # .ie <os/log.h> on macOS.
    cc_toolchain = find_cc_toolchain(ctx, mandatory = False)
    if cc_toolchain:
        transitive_inputs.append(cc_toolchain.all_files)
        args.add_all(cc_toolchain.built_in_include_directories, before_each = "-isystem")

    zig_out = ctx.actions.declare_file("{}{}_c.zig".format(output_prefix, ctx.label.name))
    ctx.actions.run_shell(
        command = "${{@}} > {}".format(zig_out.path),
        inputs = depset(
            direct = inputs,
            transitive = transitive_inputs,
        ),
        outputs = [zig_out],
        arguments = [zigtoolchaininfo.zig_exe_path, "translate-c", global_args, args],
        mnemonic = "ZigTranslateC",
        progress_message = "zig translate-c %{label}",
        execution_requirements = {tag: "" for tag in ctx.attr.tags},
        tools = zigtoolchaininfo.zig_files,
        toolchain = "//zig:toolchain_type",
    )

    # Only forward the linking context since compilation_context is now handled
    # by Zig through the generated _c.zig.
    cc_info = CcInfo(
        linking_context = linking_context,
    )

    return zig_module_info(
        name = name,
        canonical_name = "{}/{}".format(str(ctx.label), name),
        main = zig_out,
        cdeps = [cc_info],
    )
