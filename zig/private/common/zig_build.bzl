"""Common implementation of the zig_binary|library|test rules."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_android//:cc_common_link.bzl", "cc_common_link")
load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//zig/private:cc_helper.bzl", "find_cc_toolchain", "need_translate_c")
load(
    "//zig/private/common:bazel_builtin.bzl",
    "bazel_builtin_module",
    BAZEL_BUILTIN_ATTRS = "ATTRS",
)
load("//zig/private/common:cdeps.bzl", "zig_cdeps_copts", "zig_cdeps_linker_inputs")
load("//zig/private/common:csrcs.bzl", "zig_csrcs")
load("//zig/private/common:data.bzl", "zig_collect_data", "zig_create_runfiles")
load(
    "//zig/private/common:filetypes.bzl",
    "ZIG_C_SOURCE_EXTENSIONS",
    "ZIG_SOURCE_EXTENSIONS",
)
load("//zig/private/common:linker_script.bzl", "zig_linker_script")
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
    "main": attr.label(
        allow_single_file = ZIG_SOURCE_EXTENSIONS,
        doc = "The main source file.",
        mandatory = True,
    ),
    "srcs": attr.label_list(
        allow_files = ZIG_SOURCE_EXTENSIONS,
        doc = "Other Zig source files required to build the target, e.g. files imported using `@import`.",
        mandatory = False,
    ),
    "extra_srcs": attr.label_list(
        allow_files = True,
        doc = "Other files required to build the target, e.g. files embedded using `@embedFile`.",
        mandatory = False,
    ),
    "extra_docs": attr.label_list(
        allow_files = True,
        doc = "Other files required to generate documentation, e.g. guides referenced using `//!zig-autodoc-guide:`.",
        mandatory = False,
    ),
    "csrcs": attr.label_list(
        allow_files = ZIG_C_SOURCE_EXTENSIONS,
        doc = "C source files required to build the target.",
        mandatory = False,
    ),
    "copts": attr.string_list(
        doc = "C compiler flags required to build the C sources of the target. Subject to location expansion.",
        mandatory = False,
    ),
    "deps": attr.label_list(
        doc = "The list of other modules or C/C++ libraries that the library target depends upon.",
        mandatory = False,
        providers = [[ZigModuleInfo], [CcInfo]],
    ),
    "cdeps": attr.label_list(
        doc = """\
C dependencies providing headers to include and libraries to link against, typically `cc_library` targets.
Note, if you need to include C or C++ standard library headers and encounter errors of the following form:
```
note: libc headers not available; compilation does not link against libc
error: 'math.h' file not found
```
Then you may need to list `@rules_zig//zig/lib:libc` or `@rules_zig//zig/lib:libc++` in this attribute.

This is deprecated, use deps instead and pass your C/C++ dependencies there.
""",
        mandatory = False,
        providers = [CcInfo],
    ),
    "compiler_runtime": attr.string(
        doc = """\
Whether to include Zig compiler runtime symbols in the generated output.
The default behavior is to include them in executables and shared libraries.
""",
        mandatory = False,
        values = ["exclude", "include", "default"],
        default = "default",
    ),
    "linker_script": attr.label(
        doc = "Custom linker script for the target.",
        allow_single_file = True,
        mandatory = False,
    ),
    "strip_debug_symbols": attr.bool(
        doc = "Whether to pass '-fstrip' to the zig compiler to remove debug symbols.",
        mandatory = False,
        default = False,
    ),
    "data": attr.label_list(
        allow_files = True,
        doc = "Files required by the target during runtime.",
        mandatory = False,
    ),
    "zigopts": attr.string_list(
        doc = """Additional list of flags passed to the zig compiler. Subject to location expansion.

This is an advanced feature that can conflict with attributes, build settings, and other flags defined by the toolchain itself.
Use this at your own risk of hitting undefined behaviors.
""",
        mandatory = False,
    ),
    "_settings": attr.label(
        default = "//zig/settings",
        doc = "Zig build settings.",
        providers = [ZigSettingsInfo],
    ),
} | BAZEL_BUILTIN_ATTRS

COMMON_LIBRARY_ATTRS = {}

SHARED_LIBRARY_ATTRS = {
    "shared_lib_name": attr.string(
        doc = "",
        mandatory = False,
    ),
}

BINARY_ATTRS = {
    "env": attr.string_dict(
        doc = """\
Additional environment variables to set when executed by `bazel run`.
Subject to location expansion.
NOTE: The environment variables are not set when you run the target outside of Bazel (for example, by manually executing the binary in bazel-bin/).
        """,
        mandatory = False,
    ),
}

TEST_ATTRS = {
    "env": attr.string_dict(
        doc = """\
Additional environment variables to set when executed by `bazel run` or `bazel test`.
Subject to location expansion.
        """,
        mandatory = False,
    ),
    "env_inherit": attr.string_list(
        doc = """\
Environment variables to inherit from external environment when executed by `bazel test`.
        """,
        mandatory = False,
    ),
    "test_runner": attr.label(
        allow_single_file = ZIG_SOURCE_EXTENSIONS,
        doc = "Optional Zig file to specify a custom test runner",
        mandatory = False,
    ),
}

TOOLCHAINS = [
    "//zig:toolchain_type",
    "//zig/target:toolchain_type",
] + use_cc_toolchain(mandatory = False)

FRAGMENTS = ["cpp"]

def _lib_prefix(os):
    return "" if os == "windows" else "lib"

def _static_lib_extension(os):
    return ".lib" if os == "windows" else ".a"

def _shared_lib_extension(os):
    return {
        "windows": ".dll",
        "darwin": ".dylib",
        "macos": ".dylib",
    }.get(os, ".so")

def _executable_extension(os):
    return ".exe" if os == "windows" else ""

def zig_build_impl(ctx, *, kind):
    """Common implementation for Zig build rules.

    Args:
      ctx: Bazel rule context object.
      kind: String; The kind of the rule, one of `zig_binary`, `zig_static_library`, `zig_shared_library`, `zig_test`.

    Returns:
      List of providers.
    """
    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo
    zigtargetinfo = ctx.toolchains["//zig/target:toolchain_type"].zigtargetinfo

    use_cc_common_link = ctx.attr._settings[ZigSettingsInfo].use_cc_common_link

    providers = []
    exported_library_to_link = None
    direct_data = []
    transitive_data = []
    transitive_runfiles = []

    outputs = []

    direct_inputs = []
    transitive_inputs = []

    zig_collect_data(
        data = ctx.attr.data,
        deps = ctx.attr.deps,
        transitive_data = transitive_data,
        transitive_runfiles = transitive_runfiles,
    )

    args = ctx.actions.args()
    args.use_param_file("@%s")

    global_args = ctx.actions.args()
    global_args.use_param_file("@%s")

    if use_cc_common_link:
        global_args.add_all([
            # For now, linking with cc_common.link implies linking with libc.
            # But this should probably be made configurable.
            "-lc",
            # This is implied too unless disabled further down.
            # This is because zig compiler-rt ships with __zig_probe_stack which doesn't exist in regular compiler-rt.
            "-fcompiler-rt",
        ])

    if ctx.attr.compiler_runtime == "include":
        args.add("-fcompiler-rt")
    elif ctx.attr.compiler_runtime == "exclude":
        args.add("-fno-compiler-rt")

    if ctx.attr.strip_debug_symbols:
        args.add("-fstrip")

    zig_lib_dir(
        zigtoolchaininfo = zigtoolchaininfo,
        args = global_args,
    )

    zig_cache_output(
        zigtoolchaininfo = zigtoolchaininfo,
        args = global_args,
    )

    location_targets = ctx.attr.data

    default_output_is_executable = False
    default_output = None
    solib_parents = []
    if kind == "zig_binary" or kind == "zig_test":
        default_output = ctx.actions.declare_file(ctx.label.name + _executable_extension(zigtargetinfo.triple.os))
        default_output_is_executable = True

        # Calculate the RPATH components to discover the solib tree.
        # See https://github.com/bazelbuild/bazel/blob/7.0.0/src/main/java/com/google/devtools/build/lib/rules/cpp/LibrariesToLinkCollector.java#L177
        # TODO: Implement case 8b.
        solib_parents = [
            "/".join([".." for _ in ctx.label.package.split("/")]),
            paths.join(default_output.basename + ".runfiles", ctx.workspace_name),
        ]
    elif kind == "zig_static_library":
        default_output = ctx.actions.declare_file(_lib_prefix(zigtargetinfo.triple.os) + ctx.label.name + _static_lib_extension(zigtargetinfo.triple.os))
    elif kind == "zig_shared_library":
        if (ctx.attr.shared_lib_name):
            default_output = ctx.actions.declare_file(ctx.attr.shared_lib_name)
        else:
            default_output = ctx.actions.declare_file(_lib_prefix(zigtargetinfo.triple.os) + ctx.label.name + _shared_lib_extension(zigtargetinfo.triple.os))
        solib_parents = [""]

    if kind == "zig_test" and ctx.attr.test_runner:
        args.add("--test-runner", ctx.file.test_runner)
        direct_inputs.append(ctx.file.test_runner)

    outputs.append(default_output)

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

    zig_linker_script(
        linker_script = ctx.file.linker_script,
        inputs = direct_inputs,
        args = args,
    )

    zigopts = location_expansion(
        ctx = ctx,
        targets = location_targets,
        outputs = outputs,
        attribute_name = "zigopts",
        strings = ctx.attr.zigopts,
    )

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

    root_module = zig_module_info(
        name = ctx.attr.name,
        canonical_name = ctx.label.name,
        main = ctx.file.main,
        srcs = ctx.files.srcs,
        extra_srcs = ctx.files.extra_srcs,
        deps = zdeps + [bazel_builtin_module(ctx)],
        cdeps = cdeps,
        zigopts = zigopts,
    )

    zig_settings(
        settings = ctx.attr._settings[ZigSettingsInfo],
        args = global_args,
    )

    zig_target_platform(
        target = zigtargetinfo,
        args = global_args,
    )

    c_module = None
    if need_translate_c(root_module.cc_info):
        c_module = zig_translate_c(
            ctx = ctx,
            name = "c",
            zigtoolchaininfo = zigtoolchaininfo,
            global_args = global_args,
            cc_infos = [root_module.cc_info],
        )
        transitive_inputs.append(c_module.transitive_inputs)

    if root_module.cc_info:
        # Add headers to the sandbox for cImport and associated copts.
        zig_cdeps_copts(
            compilation_context = root_module.cc_info.compilation_context,
            args = args,
            transitive_inputs = transitive_inputs,
        )

        cdeps_inputs = []
        if use_cc_common_link == False:
            # Add all cdeps linker inputs to the sandbox and zig args.
            zig_cdeps_linker_inputs(
                linking_context = root_module.cc_info.linking_context,
                solib_parents = solib_parents,
                os = zigtargetinfo.triple.os,
                inputs = cdeps_inputs,
                args = args,
                data = direct_data,
            )

            transitive_inputs.append(depset(cdeps_inputs))

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

    zig_build_kwargs = dict(
        execution_requirements = {tag: "" for tag in ctx.attr.tags},
        tools = zigtoolchaininfo.zig_files,
        toolchain = "//zig:toolchain_type",
    )

    if kind == "zig_binary":
        if use_cc_common_link:
            static_lib = ctx.actions.declare_file(ctx.label.name + _static_lib_extension(zigtargetinfo.triple.os))
            args.add(static_lib, format = "-femit-bin=%s")
            ctx.actions.run(
                outputs = [static_lib],
                inputs = inputs,
                executable = zigtoolchaininfo.zig_exe_path,
                arguments = ["build-lib", global_args, args],
                mnemonic = "ZigBuildLib",
                progress_message = "zig build-lib %{label}",
                **zig_build_kwargs
            )

            cc_toolchain, feature_configuration = find_cc_toolchain(ctx, mandatory = True)
            library_to_link = cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                static_library = static_lib,
            )
            linking_context = cc_common.create_linking_context(
                linker_inputs = depset([
                    cc_common.create_linker_input(
                        owner = ctx.label,
                        libraries = depset([library_to_link]),
                    ),
                ]),
            )
            link_outputs = cc_common_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                name = ctx.label.name,
                output_type = "executable",
                main_output = default_output,
                linking_contexts = [linking_context, root_module.cc_info.linking_context],
            )
        else:
            args.add(default_output, format = "-femit-bin=%s")

            ctx.actions.run(
                outputs = [default_output],
                inputs = inputs,
                executable = zigtoolchaininfo.zig_exe_path,
                arguments = ["build-exe", global_args, args],
                mnemonic = "ZigBuildExe",
                progress_message = "zig build-exe %{label}",
                **zig_build_kwargs
            )
    elif kind == "zig_test":
        if use_cc_common_link:
            bc = ctx.actions.declare_file(ctx.label.name + ".bc")
            test_args = ctx.actions.args()
            test_args.add("-fno-emit-bin")
            test_args.add(bc, format = "-femit-llvm-bc=%s")
            ctx.actions.run(
                outputs = [bc],
                inputs = inputs,
                executable = zigtoolchaininfo.zig_exe_path,
                arguments = ["test", "--test-no-exec", global_args, args, test_args],
                mnemonic = "ZigBuildTest",
                progress_message = "zig test %{label}",
                **zig_build_kwargs
            )

            static_lib = ctx.actions.declare_file(ctx.label.name + _static_lib_extension(zigtargetinfo.triple.os))
            lib_args = ctx.actions.args()
            lib_args.add_all([
                "-fPIC",
                "-fcompiler-rt",
            ])
            lib_args.add(static_lib, format = "-femit-bin=%s")
            lib_args.add(bc)
            ctx.actions.run(
                outputs = [static_lib],
                inputs = [bc],
                executable = zigtoolchaininfo.zig_exe_path,
                arguments = ["build-lib", global_args, lib_args],
                mnemonic = "ZigBuildLib",
                progress_message = "zig build-lib %{label}",
                **zig_build_kwargs
            )

            cc_toolchain, feature_configuration = find_cc_toolchain(ctx, mandatory = True)
            library_to_link = cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                static_library = static_lib,
            )
            linking_context = cc_common.create_linking_context(
                linker_inputs = depset([
                    cc_common.create_linker_input(
                        owner = ctx.label,
                        libraries = depset([library_to_link]),
                    ),
                ]),
            )
            link_outputs = cc_common_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                name = ctx.label.name,
                output_type = "executable",
                main_output = default_output,
                linking_contexts = [linking_context, root_module.cc_info.linking_context],
            )
        else:
            args.add(default_output, format = "-femit-bin=%s")

            ctx.actions.run(
                outputs = [default_output],
                inputs = inputs,
                executable = zigtoolchaininfo.zig_exe_path,
                arguments = ["test", "--test-no-exec", global_args, args],
                mnemonic = "ZigBuildTest",
                progress_message = "zig test %{label}",
                **zig_build_kwargs
            )
    elif kind == "zig_static_library":
        args.add(default_output, format = "-femit-bin=%s")
        ctx.actions.run(
            outputs = [default_output],
            inputs = inputs,
            executable = zigtoolchaininfo.zig_exe_path,
            arguments = ["build-lib", global_args, args],
            mnemonic = "ZigBuildStaticLib",
            progress_message = "zig build-lib %{label}",
            **zig_build_kwargs
        )

        cc_toolchain, feature_configuration = find_cc_toolchain(ctx, mandatory = False)
        if cc_toolchain:
            exported_library_to_link = cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                static_library = default_output,
            )

    elif kind == "zig_shared_library":
        if use_cc_common_link:
            static_lib = ctx.actions.declare_file(ctx.label.name + _static_lib_extension(zigtargetinfo.triple.os))
            args.add(static_lib, format = "-femit-bin=%s")
            ctx.actions.run(
                outputs = [static_lib],
                inputs = inputs,
                executable = zigtoolchaininfo.zig_exe_path,
                arguments = ["build-lib", global_args, args],
                mnemonic = "ZigBuildLib",
                progress_message = "zig build-lib %{label}",
                **zig_build_kwargs
            )

            cc_toolchain, feature_configuration = find_cc_toolchain(ctx, mandatory = True)
            library_to_link = cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                static_library = static_lib,
            )
            linking_context = cc_common.create_linking_context(
                linker_inputs = depset([
                    cc_common.create_linker_input(
                        owner = ctx.label,
                        libraries = depset([library_to_link]),
                    ),
                ]),
            )
            link_outputs = cc_common_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                name = ctx.label.name,
                output_type = "dynamic_library",
                main_output = default_output,
                linking_contexts = [linking_context, root_module.cc_info.linking_context],
            )

            exported_library_to_link = link_outputs.library_to_link

        else:
            args.add(default_output, format = "-femit-bin=%s")

            ctx.actions.run(
                outputs = [default_output],
                inputs = inputs,
                executable = zigtoolchaininfo.zig_exe_path,
                arguments = ["build-lib", "-dynamic", global_args, args],
                mnemonic = "ZigBuildSharedLib",
                progress_message = "zig build-lib -dynamic %{label}",
                **zig_build_kwargs
            )

            cc_toolchain, feature_configuration = find_cc_toolchain(ctx, mandatory = False)
            if cc_toolchain:
                exported_library_to_link = cc_common.create_library_to_link(
                    actions = ctx.actions,
                    feature_configuration = feature_configuration,
                    cc_toolchain = cc_toolchain,
                    dynamic_library = default_output,
                )
    else:
        fail("Unknown rule kind '{}'.".format(kind))

    providers.extend([
        DefaultInfo(
            executable = default_output if default_output_is_executable else None,
            files = depset([default_output]),
            runfiles = zig_create_runfiles(
                ctx_runfiles = ctx.runfiles,
                direct_data = direct_data,
                transitive_data = transitive_data,
                transitive_runfiles = transitive_runfiles,
            ),
        ),
    ])

    if exported_library_to_link:
        providers.extend([
            cc_common.merge_cc_infos(
                direct_cc_infos = [
                    CcInfo(
                        linking_context = cc_common.create_linking_context(
                            linker_inputs = depset([
                                cc_common.create_linker_input(
                                    owner = ctx.label,
                                    libraries = depset([exported_library_to_link]),
                                ),
                            ]),
                        ),
                    ),
                ],
                cc_infos = [root_module.cc_info],
            ),
        ])

    if kind in ["zig_binary", "zig_test"]:
        run_environment = RunEnvironmentInfo(
            environment = dict(zip(ctx.attr.env.keys(), location_expansion(
                ctx = ctx,
                targets = location_targets,
                outputs = outputs,
                attribute_name = "env",
                strings = ctx.attr.env.values(),
            ))),
            inherited_environment = getattr(ctx.attr, "env_inherit", []),
        )
        providers.append(run_environment)

    return providers, {}
