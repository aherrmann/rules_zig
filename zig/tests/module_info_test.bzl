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
        src = mod.main.path,
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
        inputs = [],
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
                zmod.main
                for zmod in mods[mod.label.name].transitive_deps.to_list()
                if zmod.main.path == _bazel_builtin_file_name(ctx, mod.label)
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

def module_info_test_suite(name):
    _write_simple_module_expected_specs_args(
        name = "simple_expected",
        mod = "//zig/tests/multiple-sources-module:data",
        out = "simple_expected.txt",
        tags = ["manual"],
    )

    _write_module_specs_args(
        name = "simple_actual",
        mod = "//zig/tests/multiple-sources-module:data",
        out = "simple_actual.txt",
        tags = ["manual"],
    )

    diff_test(
        name = "simple_diff_test",
        failure_message = "generated module specifications do not match",
        file1 = "simple_expected.txt",
        file2 = "simple_actual.txt",
        size = "small",
    )

    _write_nested_module_expected_specs_args(
        name = "nested_expected",
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
        out = "nested_expected.txt",
        tags = ["manual"],
    )

    _write_module_specs_args(
        name = "nested_actual",
        mod = "//zig/tests/nested-modules:a",
        out = "nested_actual.txt",
        tags = ["manual"],
    )

    diff_test(
        name = "nested_diff_test",
        failure_message = "generated module specifications do not match",
        file1 = "nested_expected.txt",
        file2 = "nested_actual.txt",
        size = "small",
    )

    native.test_suite(
        name = name,
        tests = [
            "simple_diff_test",
            "nested_diff_test",
        ],
    )
