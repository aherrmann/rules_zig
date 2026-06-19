"""Unit tests for the `zig_packages` module extension helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private/bzlmod:zig_packages.bzl", "resolve_cell")

def _config(*, name, optimize = "", select_on = [], zig_flags = []):
    return struct(name = name, optimize = optimize, select_on = select_on, zig_flags = zig_flags)

def _resolve_cell_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (None, struct(
            name = "dbg",
            select_on = ["@rules_zig//zig/config/mode:debug"],
            zig_options = ["-Doptimize=Debug"],
        )),
        resolve_cell(_config(name = "dbg", optimize = "debug")),
        "optimize expands to a mode condition and -Doptimize",
    )

    asserts.equals(
        env,
        (None, struct(
            name = "x",
            select_on = ["@rules_zig//zig/config/mode:release_fast", "//my:flag"],
            zig_options = ["-Doptimize=ReleaseFast", "-DDEFINE=a=b"],
        )),
        resolve_cell(_config(
            name = "x",
            optimize = "release_fast",
            select_on = ["//my:flag"],
            zig_flags = ["DEFINE=a=b"],
        )),
        "select_on and zig_flags append; a flag value may contain '='",
    )

    asserts.equals(
        env,
        (None, struct(name = "bare", select_on = [], zig_options = [])),
        resolve_cell(_config(name = "bare")),
        "a cell may carry no conditions",
    )

    asserts.equals(
        env,
        ("config 'x' has unknown optimize mode 'fast'", None),
        resolve_cell(_config(name = "x", optimize = "fast")),
        "an unknown optimize mode is rejected",
    )

    asserts.equals(
        env,
        ("config 'x' flag 'BAD' is not NAME=VALUE", None),
        resolve_cell(_config(name = "x", zig_flags = ["BAD"])),
        "a zig_flags entry must be NAME=VALUE",
    )

    return unittest.end(env)

_resolve_cell_test = unittest.make(_resolve_cell_test_impl)

def zig_packages_test_suite(name):
    unittest.suite(
        name,
        partial.make(_resolve_cell_test, size = "small"),
    )
