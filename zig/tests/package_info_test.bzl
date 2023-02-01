"""Unit tests for ZigPackageInfo functions.
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@bazel_skylib//lib:sets.bzl", "sets")
load(
    "//zig/private/providers:zig_package_info.bzl",
    "ZigPackageInfo",
    "add_package_flags",
    "get_package_files",
)

def _mock_args():
    self_args = []

    def add_all(args, *, map_each = None):
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

    package = ctx.attr.pkg[ZigPackageInfo]

    args = _mock_args()
    add_package_flags(args, package)
    asserts.equals(
        env,
        ["--pkg-begin", package.name, package.main.path, "--pkg-end"],
        args.get_args(),
        "add_package_flags should generate the expected arguments.",
    )

    files = get_package_files(package)
    asserts.set_equals(
        env,
        sets.make([package.main] + package.srcs),
        sets.make(files.to_list()),
        "get_package_files should capture all package files.",
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

    pkgs = {
        pkg.label.name: pkg[ZigPackageInfo]
        for pkg in ctx.attr.pkgs
    }

    args = _mock_args()
    add_package_flags(args, pkgs["a"])
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
        "add_package_flags should unfold the transitive dependency graph onto the command-line.",
    )

    files = get_package_files(pkgs["a"])
    asserts.set_equals(
        env,
        sets.make([
            src
            for pkg in pkgs.values()
            for src in [pkg.main] + pkg.srcs
        ]),
        sets.make(files.to_list()),
        "get_package_files should capture all package files.",
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
