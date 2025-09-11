"""Handle translate-c pass."""

load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("//zig/private/providers:zig_module_info.bzl", "zig_module_info")

# translate-c doesn't need crt_dir
# which is a blessing because we have no way to get it from the cc_toolchain
_LIBC_TEMPLATE = """\
include_dir={include_dir}
sys_include_dir={sys_include_dir}
crt_dir=/dev/null
msvc_lib_dir=
kernel32_lib_dir=
gcc_dir=
"""

# { option: takes_value }
# translate-c only supports a limited set of clang options.
_TRANSLATE_C_OPTIONS_ALLOW_LIST = {
    "-isystem": True,
    "-idirafter": True,
    "-I": False,
    "-D": False,
}

def _find_option_argument(command_line, option_name):
    for i in range(len(command_line)):
        arg = command_line[i]
        if arg.startswith(option_name + "="):
            # Case: --option=value or -isystem=/path
            return arg.split("=", 1)[1]
        elif arg == option_name:
            # Case: --option value or -isystem /path
            if i + 1 < len(command_line):
                return command_line[i + 1]
    return None  # Not found

def _filter_options(command_line, allow_list):
    filtered_command_line = []
    skip_next = False
    for i in range(len(command_line)):
        if skip_next:
            skip_next = False
            continue

        arg = command_line[i]

        # Check for exact match, possibly with '='
        option_name = arg.split("=", 1)[0]
        if option_name in allow_list:
            expects_value = allow_list[option_name]
            if "=" in arg:
                # Handle options like -isystem=/path (=value)
                filtered_command_line.append(arg)
            else:
                # Handle the separate forms like -isystem /path
                filtered_command_line.append(arg)
                if expects_value and i + 1 < len(command_line):
                    filtered_command_line.append(command_line[i + 1])
                    skip_next = True
        else:
            # Handle options like -I/usr/include (prefix match)
            for opt in allow_list:
                if not allow_list[opt] and arg.startswith(opt):
                    filtered_command_line.append(arg)
                    break

    return filtered_command_line

def zig_translate_c(*, ctx, name, zigtoolchaininfo, global_args, cc_infos):
    """Handle translate-c build action.

    Sets the appropriate command-line flags for the Zig compiler to expose
    provided headers and link against the provided libraries.

    Args:
      ctx: CcInfo, The CcInfo provider for the C dependencies.
      name: List of String, parent RUNPATH components in `$ORIGIN/PARENT/_solib_k8`.
      zigtoolchaininfo: String, The OS component of the target triple.
      global_args: List of File; mutable, Append the needed inputs to this list.
      cc_infos: List of depset of File; mutable, Append the needed inputs to this list.

    Returns:
        `ZigModuleInfo` surrounding the generated zig file.
    """
    cc_info = cc_common.merge_cc_infos(direct_cc_infos = cc_infos)
    compilation_context = cc_info.compilation_context

    inputs = []

    hdr = ctx.actions.declare_file("{}_c.h".format(ctx.label.name))
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

    # If there is a CC toolchain, add its path there
    cc_toolchain = find_cc_toolchain(ctx)
    if cc_toolchain:
        args.add_all(cc_toolchain.built_in_include_directories, before_each = "-isystem")

        feature_configuration = cc_common.configure_features(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            requested_features = [],
            unsupported_features = [],
        )
        c_compile_variables = cc_common.create_compile_variables(
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            user_compile_flags = ctx.fragments.cpp.copts + ctx.fragments.cpp.conlyopts,
        )
        command_line = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = C_COMPILE_ACTION_NAME,
            variables = c_compile_variables,
        )

        # extracting possible sysroot before filtering the command line
        sysroot = _find_option_argument(command_line, "--sysroot")
        command_line = _filter_options(command_line, _TRANSLATE_C_OPTIONS_ALLOW_LIST)

        args.add_all(command_line)

        if cc_toolchain.sysroot:
            sysroot = cc_toolchain.sysroot

        if sysroot and sysroot != "/dev/null":
            libc_txt = ctx.actions.declare_file("libc.txt")
            ctx.actions.write(libc_txt, _LIBC_TEMPLATE.format(
                include_dir = "{}/usr/include".format(sysroot),
                sys_include_dir = "{}/usr/include".format(sysroot),
            ))
            args.add("--libc", libc_txt)
            inputs.append(libc_txt)

    zig_out = ctx.actions.declare_file("{}_c.zig".format(ctx.label.name))
    ctx.actions.run_shell(
        command = "${{@}} > {}".format(zig_out.path),
        inputs = depset(
            direct = inputs,
            transitive = [
                compilation_context.headers,
                cc_toolchain.all_files,
            ],
        ),
        outputs = [zig_out],
        arguments = [zigtoolchaininfo.zig_exe_path, "translate-c", global_args, args],
        mnemonic = "ZigTranslateC",
        progress_message = "zig translate-c {}".format(ctx.label.name),
        execution_requirements = {tag: "" for tag in ctx.attr.tags},
        tools = zigtoolchaininfo.zig_files,
        toolchain = "//zig:toolchain_type",
    )

    return zig_module_info(
        name = name,
        canonical_name = "{}/{}".format(str(ctx.label), name),
        main = zig_out,
        translated_cdeps = cc_infos,
    )
