"""Unit tests for ZigPackageInfo functions.
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@bazel_skylib//lib:sets.bzl", "sets")
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
    expected.extend(["--mod", "{name}::{src}".format(
        name = package.name,
        src = package.main.path,
    )])
    expected.extend(["--deps", package.name])

    asserts.equals(
        env,
        expected,
        args.get_args(),
        "zig_package_dependencies should generate the expected arguments.",
    )

    inputs = depset(transitive = transitive_inputs)
    asserts.set_equals(
        env,
        sets.make([package.main] + package.srcs),
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

    expected = []
    expected.extend(["--mod", "e::{}".format(pkgs["e"].main.path)])
    expected.extend(["--mod", "b:e:{}".format(pkgs["b"].main.path)])
    expected.extend(["--mod", "c:e:{}".format(pkgs["c"].main.path)])
    expected.extend(["--mod", "f:e:{}".format(pkgs["f"].main.path)])
    expected.extend(["--mod", "d:f:{}".format(pkgs["d"].main.path)])
    expected.extend(["--mod", "a:b,c,d:{}".format(pkgs["a"].main.path)])
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
            for src in [pkg.main] + pkg.srcs
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
        ),
    )
