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

    def add_all(args, *, map_each = None):
        if type(args) == "depset":
            args = args.to_list()

        if map_each != None:
            mapped = []

            for arg in args:
                result = map_each(arg)
                if result == None or result == []:
                    continue
                if type(result) == "list":
                    mapped.extend(result)
                else:
                    mapped.append(result)

            args = mapped

        for arg in args:
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
        deps = [ctx.attr.mod],
        inputs = transitive_inputs,
        args = args,
        zig_version = "0.11.0",
    )

    module = ctx.attr.mod[ZigModuleInfo]

    expected = []
    expected.extend(["--deps", module.name])
    expected.extend(_bazel_builtin_mod_flags(ctx, ctx.attr.mod.label))
    expected.extend(["--mod", "{name}:{deps}:{src}".format(
        name = module.name,
        deps = _bazel_builtin_dep(ctx.attr.mod.label),
        src = ctx.file.mod_main.path,
    )])

    asserts.equals(
        env,
        expected,
        args.get_args(),
        "zig_module_dependencies should generate the expected arguments.",
    )

    bazel_builtin_file = [
        file
        for file in module.transitive_inputs.to_list()
        if file.path == _bazel_builtin_file_name(ctx, ctx.attr.mod.label)
    ]

    inputs = depset(transitive = transitive_inputs)
    asserts.set_equals(
        env,
        sets.make([ctx.file.mod_main] + ctx.files.mod_srcs + bazel_builtin_file),
        sets.make(inputs.to_list()),
        "zig_module_dependencies should capture all module files.",
    )

    return unittest.end(env)

_single_module_test = unittest.make(
    _single_module_test_impl,
    attrs = {
        "mod": attr.label(providers = [ZigModuleInfo]),
        "mod_main": attr.label(allow_single_file = True),
        "mod_srcs": attr.label_list(allow_files = True),
    },
)

def _nested_modules_test_impl(ctx):
    env = unittest.begin(ctx)

    transitive_inputs = []
    args = _mock_args()

    zig_module_dependencies(
        deps = [dep for dep in ctx.attr.mods if dep.label.name == "a"],
        inputs = transitive_inputs,
        args = args,
        zig_version = "0.11.0",
    )

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
    expected.extend(["--deps", "a"])
    expected.extend(bazel_builtins["e"].mod_flags)
    expected.extend(["--mod", "e:{}:{}".format(bazel_builtins["e"].dep, mod_mains["e"].path)])
    expected.extend(bazel_builtins["b"].mod_flags)
    expected.extend(["--mod", "b:e,{}:{}".format(bazel_builtins["b"].dep, mod_mains["b"].path)])
    expected.extend(bazel_builtins["c"].mod_flags)
    expected.extend(["--mod", "c:e,{}:{}".format(bazel_builtins["c"].dep, mod_mains["c"].path)])
    expected.extend(bazel_builtins["f"].mod_flags)
    expected.extend(["--mod", "f:e,{}:{}".format(bazel_builtins["f"].dep, mod_mains["f"].path)])
    expected.extend(bazel_builtins["d"].mod_flags)
    expected.extend(["--mod", "d:f,{}:{}".format(bazel_builtins["d"].dep, mod_mains["d"].path)])
    expected.extend(bazel_builtins["a"].mod_flags)
    expected.extend(["--mod", "a:b,c,d,{}:{}".format(bazel_builtins["a"].dep, mod_mains["a"].path)])

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
            for mod in mods.values()
            for src in [mod_mains[mod.name]] + bazel_builtins[mod.name].file
        ]),
        sets.make(inputs.to_list()),
        "zig_module_dependencies should capture all module files.",
    )

    return unittest.end(env)

_nested_modules_test = unittest.make(
    _nested_modules_test_impl,
    attrs = {
        "mods": attr.label_list(providers = [ZigModuleInfo]),
        "mod_mains": attr.label_list(allow_files = True),
    },
)

def module_info_test_suite(name):
    unittest.suite(
        name,
        lambda name: _single_module_test(
            name = name,
            mod = "//zig/tests/multiple-sources-module:data",
            mod_main = "//zig/tests/multiple-sources-module:data.zig",
            mod_srcs = [
                "//zig/tests/multiple-sources-module:data/hello.zig",
                "//zig/tests/multiple-sources-module:data/world.zig",
            ],
            size = "small",
        ),
        lambda name: _nested_modules_test(
            name = name,
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
            size = "small",
        ),
    )
