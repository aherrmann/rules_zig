"""Unit tests for ZigPackageInfo functions.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//zig/private/providers:zig_package_info.bzl",
    "ZigPackageInfo",
    "zig_package_dependencies",
)

def _mock_args():
    self_args = []

    def add_all(args, *, before_each = None):
        if type(args) == "depset":
            args = args.to_list()
        for arg in args:
            if before_each:
                self_args.append(before_each)
            if type(arg) == "File":
                self_args.append(arg.path)
            else:
                self_args.append(arg)

    def add_joined(arg_name, args, *, join_with):
        if args:
            self_args.append(arg_name)
            self_args.append(join_with.join(args))

    def get_args():
        return self_args

    return struct(
        add_all = add_all,
        add_joined = add_joined,
        get_args = get_args,
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
    return ["--mod", "{}::{}".format(
        _bazel_builtin_name(label),
        _bazel_builtin_file_name(ctx, label),
    )]

def _bazel_builtin_dep(label):
    return "bazel_builtin={}".format(_bazel_builtin_name(label))

def _single_package_test_impl(ctx):
    env = unittest.begin(ctx)

    transitive_inputs = []
    args = _mock_args()

    zig_package_dependencies(
        deps = [ctx.attr.pkg],
        inputs = transitive_inputs,
        args = args,
    )

    package = ctx.attr.pkg[ZigPackageInfo]

    expected = []
    expected.extend(_bazel_builtin_mod_flags(ctx, ctx.attr.pkg.label))
    expected.extend(["--mod", "{name}:{deps}:{src}".format(
        name = package.name,
        deps = _bazel_builtin_dep(ctx.attr.pkg.label),
        src = package.main.path,
    )])
    expected.extend(["--deps", package.name])

    asserts.equals(
        env,
        expected,
        args.get_args(),
        "zig_package_dependencies should generate the expected arguments.",
    )

    bazel_builtin_file = [
        file
        for file in package.all_srcs.to_list()
        if file.path == _bazel_builtin_file_name(ctx, ctx.attr.pkg.label)
    ]

    inputs = depset(transitive = transitive_inputs)
    asserts.set_equals(
        env,
        sets.make([package.main] + package.srcs + bazel_builtin_file),
        sets.make(inputs.to_list()),
        "zig_package_dependencies should capture all package files.",
    )

    return unittest.end(env)

_single_package_test = unittest.make(
    _single_package_test_impl,
    attrs = {
        "pkg": attr.label(providers = [ZigPackageInfo]),
    },
)

def _nested_packages_test_impl(ctx):
    env = unittest.begin(ctx)

    transitive_inputs = []
    args = _mock_args()

    zig_package_dependencies(
        deps = [dep for dep in ctx.attr.pkgs if dep.label.name == "a"],
        inputs = transitive_inputs,
        args = args,
    )

    pkgs = {
        pkg.label.name: pkg[ZigPackageInfo]
        for pkg in ctx.attr.pkgs
    }

    bazel_builtins = {
        pkg.label.name: struct(
            mod_flags = _bazel_builtin_mod_flags(ctx, pkg.label),
            dep = _bazel_builtin_dep(pkg.label),
            file = [
                file
                for file in pkgs[pkg.label.name].all_srcs.to_list()
                if file.path == _bazel_builtin_file_name(ctx, pkg.label)
            ],
        )
        for pkg in ctx.attr.pkgs
    }

    expected = []
    expected.extend(bazel_builtins["e"].mod_flags)
    expected.extend(["--mod", "e:{}:{}".format(bazel_builtins["e"].dep, pkgs["e"].main.path)])
    expected.extend(bazel_builtins["b"].mod_flags)
    expected.extend(["--mod", "b:e,{}:{}".format(bazel_builtins["b"].dep, pkgs["b"].main.path)])
    expected.extend(bazel_builtins["c"].mod_flags)
    expected.extend(["--mod", "c:e,{}:{}".format(bazel_builtins["c"].dep, pkgs["c"].main.path)])
    expected.extend(bazel_builtins["f"].mod_flags)
    expected.extend(["--mod", "f:e,{}:{}".format(bazel_builtins["f"].dep, pkgs["f"].main.path)])
    expected.extend(bazel_builtins["d"].mod_flags)
    expected.extend(["--mod", "d:f,{}:{}".format(bazel_builtins["d"].dep, pkgs["d"].main.path)])
    expected.extend(bazel_builtins["a"].mod_flags)
    expected.extend(["--mod", "a:b,c,d,{}:{}".format(bazel_builtins["a"].dep, pkgs["a"].main.path)])
    expected.extend(["--deps", "a"])

    asserts.equals(
        env,
        expected,
        args.get_args(),
        "zig_package_dependencies should unfold the transitive dependency graph onto the command-line.",
    )

    inputs = depset(transitive = transitive_inputs)
    asserts.set_equals(
        env,
        sets.make([
            src
            for pkg in pkgs.values()
            for src in [pkg.main] + pkg.srcs + bazel_builtins[pkg.name].file
        ]),
        sets.make(inputs.to_list()),
        "zig_package_dependencies should capture all package files.",
    )

    return unittest.end(env)

_nested_packages_test = unittest.make(
    _nested_packages_test_impl,
    attrs = {
        "pkgs": attr.label_list(providers = [ZigPackageInfo]),
    },
)

def package_info_test_suite(name):
    unittest.suite(
        name,
        lambda name: _single_package_test(
            name = name,
            pkg = "//zig/tests/multiple-sources-package:data",
            size = "small",
        ),
        lambda name: _nested_packages_test(
            name = name,
            pkgs = [
                "//zig/tests/nested-packages:a",
                "//zig/tests/nested-packages:b",
                "//zig/tests/nested-packages:c",
                "//zig/tests/nested-packages:d",
                "//zig/tests/nested-packages:e",
                "//zig/tests/nested-packages:f",
            ],
            size = "small",
        ),
    )
