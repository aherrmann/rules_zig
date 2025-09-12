"""Unit tests for ZigModuleInfo functions.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load(
    "//zig/private/providers:zig_module_info.bzl",
    "ZigModuleInfo",
    "zig_module_specifications",
)

def _bazel_builtin_name(label):
    return "bazel_builtin_A{repo}_S_S{package}_C{target}".format(
        repo = label.repo_name if hasattr(label, "repo_name") else label.workspace_name,
        package = label.package.replace("/", "_S"),
        target = label.name,
    )

def _bazel_builtin_file_name(ctx, label):
    return paths.join(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
        _bazel_builtin_name(label) + ".zig",
    )

def _bazel_builtin_mod_flags(ctx, label):
    return ["'-M{}={}'".format(
        _bazel_builtin_name(label),
        _bazel_builtin_file_name(ctx, label),
    )]

def _bazel_builtin_dep(label):
    return "'bazel_builtin={}'".format(_bazel_builtin_name(label))

def _write_simple_module_expected_specs_args_impl(ctx):
    mod = ctx.attr.mod[ZigModuleInfo]

    expected = []
    expected.extend(["--dep", _bazel_builtin_dep(ctx.attr.mod.label)])
    expected.extend(["'-M{name}={src}'".format(
        name = mod.name,
        src = ctx.file.mod_main.path,
    )])
    expected.extend(_bazel_builtin_mod_flags(ctx, ctx.attr.mod.label))

    ctx.actions.write(
        output = ctx.outputs.out,
        content = "\n".join(expected) + "\n",
    )

_write_simple_module_expected_specs_args = rule(
    _write_simple_module_expected_specs_args_impl,
    attrs = {
        "mod": attr.label(providers = [ZigModuleInfo]),
        "mod_main": attr.label(allow_single_file = True),
        "out": attr.output(mandatory = True),
    },
)

def _write_module_specs_args_impl(ctx):
    args = ctx.actions.args()

    zig_module_specifications(
        root_module = ctx.attr.mod[ZigModuleInfo],
        args = args,
    )

    ctx.actions.write(
        output = ctx.outputs.out,
        content = args,
    )

_write_module_specs_args = rule(
    _write_module_specs_args_impl,
    attrs = {
        "mod": attr.label(providers = [ZigModuleInfo]),
        "out": attr.output(mandatory = True),
    },
)

def _write_nested_module_expected_specs_args_impl(ctx):
    mods = {
        mod.label.name: mod[ZigModuleInfo]
        for mod in ctx.attr.mods
    }

    mod_mains = {
        mod.label.name: main
        for (mod, main) in zip(ctx.attr.mods, ctx.files.mod_mains)
    }

    bazel_builtins = {
        mod.label.name: struct(
            mod_flags = _bazel_builtin_mod_flags(ctx, mod.label),
            dep = _bazel_builtin_dep(mod.label),
            file = [
                file
                for file in mods[mod.label.name].transitive_inputs.to_list()
                if file.path == _bazel_builtin_file_name(ctx, mod.label)
            ],
        )
        for mod in ctx.attr.mods
    }

    expected = []
    expected.extend([
        "--dep",
        "'b=b'",
        "--dep",
        "'c=c'",
        "--dep",
        "'d=d'",
        "--dep",
        bazel_builtins["a"].dep,
        "'-Ma={}'".format(mod_mains["a"].path),
    ])

    expected.extend(bazel_builtins["e"].mod_flags)
    expected.extend([
        "--dep",
        bazel_builtins["e"].dep,
        "'-Me={}'".format(mod_mains["e"].path),
    ])
    expected.extend(bazel_builtins["b"].mod_flags)
    expected.extend(bazel_builtins["c"].mod_flags)
    expected.extend(bazel_builtins["f"].mod_flags)

    expected.extend([
        "--dep",
        "'e=e'",
        "--dep",
        bazel_builtins["f"].dep,
        "'-Mf={}'".format(mod_mains["f"].path),
    ])
    expected.extend(bazel_builtins["d"].mod_flags)
    expected.extend([
        "--dep",
        "'e=e'",
        "--dep",
        bazel_builtins["b"].dep,
        "'-Mb={}'".format(mod_mains["b"].path),
    ])
    expected.extend([
        "--dep",
        "'e=e'",
        "--dep",
        bazel_builtins["c"].dep,
        "'-Mc={}'".format(mod_mains["c"].path),
    ])
    expected.extend([
        "--dep",
        "'f=f'",
        "--dep",
        bazel_builtins["d"].dep,
        "'-Md={}'".format(mod_mains["d"].path),
    ])
    expected.extend(bazel_builtins["a"].mod_flags)

    ctx.actions.write(
        output = ctx.outputs.out,
        content = "\n".join(expected) + "\n",
    )

_write_nested_module_expected_specs_args = rule(
    _write_nested_module_expected_specs_args_impl,
    attrs = {
        "mods": attr.label_list(providers = [ZigModuleInfo]),
        "mod_mains": attr.label_list(allow_files = True),
        "out": attr.output(mandatory = True),
    },
)

def _write_simple_module_with_c_expected_specs_args_impl(ctx):
    mods = {
        mod.label.name: mod[ZigModuleInfo]
        for mod in ctx.attr.mods
    }

    bazel_builtins = {
        mod.label.name: struct(
            mod_flags = _bazel_builtin_mod_flags(ctx, mod.label),
            dep = _bazel_builtin_dep(mod.label),
            file = [
                file
                for file in mods[mod.label.name].transitive_inputs.to_list()
                if file.path == _bazel_builtin_file_name(ctx, mod.label)
            ],
        )
        for mod in ctx.attr.mods
    }

    expected = []
    expected.extend(["--dep", "'data_c_zig={}'".format(mods["data_c_zig"].module_context.canonical_name)])
    expected.extend(["--dep", bazel_builtins["data"].dep])
    expected.extend(["'-M{name}={src}'".format(
        name = mods["data"].name,
        src = mods["data"].module_context.main,
    )])
    expected.extend(["'-M{}={}'".format(mods["data_c_zig"].module_context.canonical_name, mods["data_c_zig"].module_context.main)])
    expected.extend(bazel_builtins["data"].mod_flags)

    ctx.actions.write(
        output = ctx.outputs.out,
        content = "\n".join(expected) + "\n",
    )

_write_simple_module_with_c_expected_specs_args = rule(
    _write_simple_module_with_c_expected_specs_args_impl,
    attrs = {
        "mods": attr.label_list(providers = [ZigModuleInfo]),
        "mod_mains": attr.label_list(allow_files = True),
        "out": attr.output(mandatory = True),
    },
)

def module_info_test_suite(name):
    """Generate module info test suite.

    Args:
        name: The name of the test suite.
    """
    _write_simple_module_expected_specs_args(
        name = name + "_simple_expected",
        mod = "//zig/tests/multiple-sources-module:data",
        mod_main = "//zig/tests/multiple-sources-module:data.zig",
        out = name + "_simple_expected.txt",
        tags = ["manual"],
    )

    _write_module_specs_args(
        name = name + "_simple_actual",
        mod = "//zig/tests/multiple-sources-module:data",
        out = name + "_simple_actual.txt",
        tags = ["manual"],
    )

    diff_test(
        name = name + "_simple_diff_test",
        failure_message = "generated module specifications do not match",
        file1 = name + "_simple_expected.txt",
        file2 = name + "_simple_actual.txt",
        size = "small",
    )

    _write_simple_module_with_c_expected_specs_args(
        name = name + "_simple_with_c_expected",
        mods = [
            "//zig/tests/translate-c-modules:data_c_zig",
            "//zig/tests/translate-c-modules:data",
        ],
        mod_mains = [
            "//zig/tests/translate-c-modules:data.zig",
        ],
        out = name + "_simple_with_c_expected.txt",
        tags = ["manual"],
    )

    _write_module_specs_args(
        name = name + "_simple_with_c_actual",
        mod = "//zig/tests/translate-c-modules:data",
        out = name + "_simple_with_c_actual.txt",
        tags = ["manual"],
    )

    diff_test(
        name = name + "_simple_with_c_diff_test",
        failure_message = "generated module specifications do not match",
        file1 = name + "_simple_with_c_expected.txt",
        file2 = name + "_simple_with_c_actual.txt",
        size = "small",
    )

    _write_nested_module_expected_specs_args(
        name = name + "_nested_expected",
        mods = [
            "//zig/tests/nested-modules:a",
            "//zig/tests/nested-modules:b",
            "//zig/tests/nested-modules:c",
            "//zig/tests/nested-modules:d",
            "//zig/tests/nested-modules:e",
            "//zig/tests/nested-modules:f",
        ],
        mod_mains = [
            "//zig/tests/nested-modules:a.zig",
            "//zig/tests/nested-modules:b.zig",
            "//zig/tests/nested-modules:c.zig",
            "//zig/tests/nested-modules:d.zig",
            "//zig/tests/nested-modules:e.zig",
            "//zig/tests/nested-modules:f.zig",
        ],
        out = name + "_nested_expected.txt",
        tags = ["manual"],
    )

    _write_module_specs_args(
        name = name + "_nested_actual",
        mod = "//zig/tests/nested-modules:a",
        out = name + "_nested_actual.txt",
        tags = ["manual"],
    )

    diff_test(
        name = name + "_nested_diff_test",
        failure_message = "generated module specifications do not match",
        file1 = name + "_nested_expected.txt",
        file2 = name + "_nested_actual.txt",
        size = "small",
    )

    native.test_suite(
        name = name,
        tests = [
            name + "_simple_diff_test",
            name + "_nested_diff_test",
            name + "_simple_with_c_diff_test",
        ],
    )
