"""Unit tests for ZigModuleInfo functions.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//zig/private/providers:zig_module_info.bzl",
    "ZigModuleInfo",
    "zig_module_dependencies",
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

def _single_module_test_impl(ctx):
    env = unittest.begin(ctx)

    transitive_inputs = []
    args = _mock_args()

    zig_module_dependencies(
        deps = [ctx.attr.pkg],
        inputs = transitive_inputs,
        args = args,
    )

    module = ctx.attr.pkg[ZigModuleInfo]

    expected = []
    expected.extend(_bazel_builtin_mod_flags(ctx, ctx.attr.pkg.label))
    expected.extend(["--mod", "{name}:{deps}:{src}".format(
        name = module.name,
        deps = _bazel_builtin_dep(ctx.attr.pkg.label),
        src = ctx.file.pkg_main.path,
    )])
    expected.extend(["--deps", module.name])

    asserts.equals(
        env,
        expected,
        args.get_args(),
        "zig_module_dependencies should generate the expected arguments.",
    )

    bazel_builtin_file = [
        file
        for file in module.all_srcs.to_list()
        if file.path == _bazel_builtin_file_name(ctx, ctx.attr.pkg.label)
    ]

    inputs = depset(transitive = transitive_inputs)
    asserts.set_equals(
        env,
        sets.make([ctx.file.pkg_main] + ctx.files.pkg_srcs + bazel_builtin_file),
        sets.make(inputs.to_list()),
        "zig_module_dependencies should capture all module files.",
    )

    return unittest.end(env)

_single_module_test = unittest.make(
    _single_module_test_impl,
    attrs = {
        "pkg": attr.label(providers = [ZigModuleInfo]),
        "pkg_main": attr.label(allow_single_file = True),
        "pkg_srcs": attr.label_list(allow_files = True),
    },
)

def _nested_modules_test_impl(ctx):
    env = unittest.begin(ctx)

    transitive_inputs = []
    args = _mock_args()

    zig_module_dependencies(
        deps = [dep for dep in ctx.attr.pkgs if dep.label.name == "a"],
        inputs = transitive_inputs,
        args = args,
    )

    pkgs = {
        pkg.label.name: pkg[ZigModuleInfo]
        for pkg in ctx.attr.pkgs
    }

    pkg_mains = {
        pkg.label.name: main
        for (pkg, main) in zip(ctx.attr.pkgs, ctx.files.pkg_mains)
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
    expected.extend(["--mod", "e:{}:{}".format(bazel_builtins["e"].dep, pkg_mains["e"].path)])
    expected.extend(bazel_builtins["b"].mod_flags)
    expected.extend(["--mod", "b:e,{}:{}".format(bazel_builtins["b"].dep, pkg_mains["b"].path)])
    expected.extend(bazel_builtins["c"].mod_flags)
    expected.extend(["--mod", "c:e,{}:{}".format(bazel_builtins["c"].dep, pkg_mains["c"].path)])
    expected.extend(bazel_builtins["f"].mod_flags)
    expected.extend(["--mod", "f:e,{}:{}".format(bazel_builtins["f"].dep, pkg_mains["f"].path)])
    expected.extend(bazel_builtins["d"].mod_flags)
    expected.extend(["--mod", "d:f,{}:{}".format(bazel_builtins["d"].dep, pkg_mains["d"].path)])
    expected.extend(bazel_builtins["a"].mod_flags)
    expected.extend(["--mod", "a:b,c,d,{}:{}".format(bazel_builtins["a"].dep, pkg_mains["a"].path)])
    expected.extend(["--deps", "a"])

    asserts.equals(
        env,
        expected,
        args.get_args(),
        "zig_module_dependencies should unfold the transitive dependency graph onto the command-line.",
    )

    inputs = depset(transitive = transitive_inputs)
    asserts.set_equals(
        env,
        sets.make([
            src
            for pkg in pkgs.values()
            for src in [pkg_mains[pkg.name]] + bazel_builtins[pkg.name].file
        ]),
        sets.make(inputs.to_list()),
        "zig_module_dependencies should capture all module files.",
    )

    return unittest.end(env)

_nested_modules_test = unittest.make(
    _nested_modules_test_impl,
    attrs = {
        "pkgs": attr.label_list(providers = [ZigModuleInfo]),
        "pkg_mains": attr.label_list(allow_files = True),
    },
)

def module_info_test_suite(name):
    unittest.suite(
        name,
        lambda name: _single_module_test(
            name = name,
            pkg = "//zig/tests/multiple-sources-module:data",
            pkg_main = "//zig/tests/multiple-sources-module:data.zig",
            pkg_srcs = [
                "//zig/tests/multiple-sources-module:data/hello.zig",
                "//zig/tests/multiple-sources-module:data/world.zig",
            ],
            size = "small",
        ),
        lambda name: _nested_modules_test(
            name = name,
            pkgs = [
                "//zig/tests/nested-modules:a",
                "//zig/tests/nested-modules:b",
                "//zig/tests/nested-modules:c",
                "//zig/tests/nested-modules:d",
                "//zig/tests/nested-modules:e",
                "//zig/tests/nested-modules:f",
            ],
            pkg_mains = [
                "//zig/tests/nested-modules:a.zig",
                "//zig/tests/nested-modules:b.zig",
                "//zig/tests/nested-modules:c.zig",
                "//zig/tests/nested-modules:d.zig",
                "//zig/tests/nested-modules:e.zig",
                "//zig/tests/nested-modules:f.zig",
            ],
            size = "small",
        ),
    )
