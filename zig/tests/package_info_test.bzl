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

    def add_all(args):
        for arg in args:
            if type(arg) == "File":
                self_args.append(arg.path)
            else:
                self_args.append(arg)

    def get_args():
        return self_args

    return struct(
        add_all = add_all,
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

    asserts.equals(
        env,
        ["--pkg-begin", package.name, package.main.path, "--pkg-end"],
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

    asserts.equals(
        env,
        [
            # a <-- b, c, d
            "--pkg-begin",
            pkgs["a"].name,
            pkgs["a"].main.path,
            # b <-- e
            "--pkg-begin",
            pkgs["b"].name,
            pkgs["b"].main.path,
            # e
            "--pkg-begin",
            pkgs["e"].name,
            pkgs["e"].main.path,
            # /e
            "--pkg-end",
            # /b
            "--pkg-end",
            # c <-- e
            "--pkg-begin",
            pkgs["c"].name,
            pkgs["c"].main.path,
            # e
            "--pkg-begin",
            pkgs["e"].name,
            pkgs["e"].main.path,
            # /e
            "--pkg-end",
            # /c
            "--pkg-end",
            # d <-- f
            "--pkg-begin",
            pkgs["d"].name,
            pkgs["d"].main.path,
            # f <-- e
            "--pkg-begin",
            pkgs["f"].name,
            pkgs["f"].main.path,
            # e
            "--pkg-begin",
            pkgs["e"].name,
            pkgs["e"].main.path,
            # /e
            "--pkg-end",
            # /f
            "--pkg-end",
            # /d
            "--pkg-end",
            # /a
            "--pkg-end",
        ],
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
