"""Common implementation of the zig_binary|library|test rules."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    "//zig/private/common:bazel_builtin.bzl",
    "bazel_builtin_module",
    BAZEL_BUILTIN_ATTRS = "ATTRS",
)
load("//zig/private/common:cdeps.bzl", "zig_cdeps")
load("//zig/private/common:csrcs.bzl", "zig_csrcs")
load("//zig/private/common:data.bzl", "zig_collect_data", "zig_create_runfiles")
load(
    "//zig/private/common:filetypes.bzl",
    "ZIG_C_SOURCE_EXTENSIONS",
    "ZIG_SOURCE_EXTENSIONS",
)
load("//zig/private/common:linker_script.bzl", "zig_linker_script")
load("//zig/private/common:location_expansion.bzl", "location_expansion")
load("//zig/private/common:zig_cache.bzl", "zig_cache_output")
load("//zig/private/common:zig_lib_dir.bzl", "zig_lib_dir")
load(
    "//zig/private/providers:zig_module_info.bzl",
    "ZigModuleInfo",
    "zig_module_dependencies",
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
        doc = "modules required to build the target.",
        mandatory = False,
        providers = [ZigModuleInfo],
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
""",
        mandatory = False,
        providers = [CcInfo],
    ),
    "linker_script": attr.label(
        doc = "Custom linker script for the target.",
        allow_single_file = True,
        mandatory = False,
    ),
    "data": attr.label_list(
        allow_files = True,
        doc = "Files required by the target during runtime.",
        mandatory = False,
    ),
    "_settings": attr.label(
        default = "//zig/settings",
        doc = "Zig build settings.",
        providers = [ZigSettingsInfo],
    ),
} | BAZEL_BUILTIN_ATTRS

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
}

TOOLCHAINS = [
    "//zig:toolchain_type",
    "//zig/target:toolchain_type",
]

def zig_build_impl(ctx, *, kind):
    """Common implementation for Zig build rules.

    Args:
      ctx: Bazel rule context object.
      kind: String; The kind of the rule, one of `zig_binary`, `zig_library`, `zig_shared_library`, `zig_test`.

    Returns:
      List of providers.
    """
    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo
    zigtargetinfo = ctx.toolchains["//zig/target:toolchain_type"].zigtargetinfo

    executable = None
    files = None
    direct_data = []
    transitive_data = []
    transitive_runfiles = []

    outputs = []

    direct_inputs = []
    transitive_inputs = []

    zig_collect_data(
        data = ctx.attr.data,
        deps = ctx.attr.deps + ctx.attr.cdeps,
        transitive_data = transitive_data,
        transitive_runfiles = transitive_runfiles,
    )

    args = ctx.actions.args()
    args.use_param_file("@%s")

    if kind == "zig_binary" or kind == "zig_test":
        extension = ".exe" if zigtargetinfo.triple.os == "windows" else ""
        output = ctx.actions.declare_file(ctx.label.name + extension)
        outputs.append(output)
        args.add(output, format = "-femit-bin=%s")

        executable = output
        files = depset([output])
        direct_data.append(output)

        # Calculate the RPATH components to discover the solib tree.
        # See https://github.com/bazelbuild/bazel/blob/7.0.0/src/main/java/com/google/devtools/build/lib/rules/cpp/LibrariesToLinkCollector.java#L177
        # TODO: Implement case 8b.
        solib_parents = [
            "/".join([".." for _ in ctx.label.package.split("/")]),
            paths.join(output.basename + ".runfiles", ctx.workspace_name),
        ]
    elif kind == "zig_library":
        prefix = "" if zigtargetinfo.triple.os == "windows" else "lib"
        extension = ".lib" if zigtargetinfo.triple.os == "windows" else ".a"
        static = ctx.actions.declare_file(prefix + ctx.label.name + extension)
        outputs.append(static)
        args.add(static, format = "-femit-bin=%s")

        files = depset([static])

        solib_parents = []
    elif kind == "zig_shared_library":
        prefix = "" if zigtargetinfo.triple.os == "windows" else "lib"
        extension = ".dll" if zigtargetinfo.triple.os == "windows" else ".so"
        dynamic = ctx.actions.declare_file(prefix + ctx.label.name + extension)
        outputs.append(dynamic)
        args.add(dynamic, format = "-femit-bin=%s")
        args.add(dynamic.basename, format = "-fsoname=%s")

        files = depset([dynamic])

        solib_parents = [""]
    else:
        fail("Unknown rule kind '{}'.".format(kind))

    zig_lib_dir(
        zigtoolchaininfo = zigtoolchaininfo,
        args = args,
    )

    zig_cache_output(
        zigtoolchaininfo = zigtoolchaininfo,
        args = args,
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

    zig_cdeps(
        cdeps = ctx.attr.cdeps,
        solib_parents = solib_parents,
        os = zigtargetinfo.triple.os,
        direct_inputs = direct_inputs,
        transitive_inputs = transitive_inputs,
        args = args,
        data = direct_data,
    )

    zig_linker_script(
        linker_script = ctx.file.linker_script,
        inputs = direct_inputs,
        args = args,
    )

    direct_inputs.append(ctx.file.main)
    direct_inputs.extend(ctx.files.srcs)
    direct_inputs.extend(ctx.files.extra_srcs)

    bazel_builtin = bazel_builtin_module(ctx)

    zig_module_dependencies(
        deps = ctx.attr.deps,
        extra_deps = [bazel_builtin],
        args = args,
        zig_version = zigtoolchaininfo.zig_version,
    )

    zig_settings(
        settings = ctx.attr._settings[ZigSettingsInfo],
        args = args,
    )

    zig_target_platform(
        target = zigtargetinfo,
        args = args,
    )

    if zigtoolchaininfo.zig_version.startswith("0.11."):
        args.add_all(["--main-pkg-path", "."])
        args.add(ctx.file.main)
    else:
        args.add(ctx.file.main, format = "-M{}=%s".format(ctx.label.name))

    zig_module_specifications(
        deps = ctx.attr.deps,
        extra_deps = [bazel_builtin],
        inputs = transitive_inputs,
        args = args,
        zig_version = zigtoolchaininfo.zig_version,
    )

    inputs = depset(
        direct = direct_inputs,
        transitive = transitive_inputs,
        order = "preorder",
    )

    if kind == "zig_binary":
        arguments = ["build-exe", args]
        mnemonic = "ZigBuildExe"
        progress_message = "Building %{input} as Zig binary %{output}"
    elif kind == "zig_test":
        arguments = ["test", "--test-no-exec", args]
        mnemonic = "ZigBuildTest"
        progress_message = "Building %{input} as Zig test %{output}"
    elif kind == "zig_library":
        arguments = ["build-lib", args]
        mnemonic = "ZigBuildLib"
        progress_message = "Building %{input} as Zig library %{output}"
    elif kind == "zig_shared_library":
        arguments = ["build-lib", "-dynamic", args]
        mnemonic = "ZigBuildSharedLib"
        progress_message = "Building %{input} as Zig shared library %{output}"
    else:
        fail("Unknown rule kind '{}'.".format(kind))

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

    default = DefaultInfo(
        executable = executable,
        files = files,
        runfiles = zig_create_runfiles(
            ctx_runfiles = ctx.runfiles,
            direct_data = direct_data,
            transitive_data = transitive_data,
            transitive_runfiles = transitive_runfiles,
        ),
    )
    providers.append(default)

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

    return providers
