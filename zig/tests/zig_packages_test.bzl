"""Unit tests for the `zig_packages` module extension helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private/bzlmod:zig_packages.bzl", "check_cells", "package_name_version", "resolve_cell")

def _config(*, name, optimize = "", select_on = [], zig_flags = []):
    return struct(name = name, optimize = optimize, select_on = select_on, zig_flags = zig_flags)

def _cell(*, name, select_on = [], zig_options = [], config_setting = ""):
    return struct(name = name, select_on = select_on, zig_options = zig_options, config_setting = config_setting)

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

def _check_cells_test_impl(ctx):
    env = unittest.begin(ctx)

    fallback = _cell(name = "dbg", select_on = ["//mode:debug"], config_setting = "")
    rel = _cell(name = "rel", select_on = ["//mode:release"], zig_options = ["-Doptimize=ReleaseFast"], config_setting = "rel")

    asserts.equals(
        env,
        (None, [fallback, rel]),
        check_cells("pkg", [fallback, rel]),
        "a fallback and a distinct non-fallback cell pass through",
    )

    duplicate = _cell(name = "rel2", select_on = ["//mode:release"], zig_options = ["-Doptimize=ReleaseFast"], config_setting = "rel2")
    asserts.equals(
        env,
        (None, [fallback, rel]),
        check_cells("pkg", [fallback, rel, duplicate]),
        "duplicate cells are merged",
    )

    conflicting = _cell(name = "rel3", select_on = ["//mode:release"], zig_options = ["-Doptimize=ReleaseSafe"], config_setting = "rel3")
    asserts.equals(
        env,
        ("package 'pkg' configs 'rel' and 'rel3' share conditions but differ in build options", None),
        check_cells("pkg", [fallback, rel, conflicting]),
        "shared conditions with differing options conflict",
    )

    general = _cell(name = "g", select_on = ["//os:linux"], config_setting = "g")
    specific = _cell(name = "s", select_on = ["//os:linux", "//mode:release"], config_setting = "s")
    asserts.equals(
        env,
        ("package 'pkg' config 'g' conditions are a subset of 's'; they would match ambiguously", None),
        check_cells("pkg", [fallback, general, specific]),
        "a cell whose conditions are a subset of another's is rejected",
    )

    asserts.equals(
        env,
        ("package 'pkg' config 'e' has no select conditions", None),
        check_cells("pkg", [fallback, _cell(name = "e", config_setting = "e")]),
        "a non-fallback cell must have conditions",
    )

    return unittest.end(env)

_check_cells_test = unittest.make(_check_cells_test_impl)

def _package_name_version_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        ("cfgdep", "0.0.0"),
        package_name_version("cfgdep-0.0.0-AAAABBBBCCCC"),
        "name and version split off the digest",
    )

    asserts.equals(
        env,
        ("ezi_gex", "0.5.0-dev"),
        package_name_version("ezi_gex-0.5.0-dev-fTQAPBMbFwDJ"),
        "a version may itself contain '-'",
    )

    return unittest.end(env)

_package_name_version_test = unittest.make(_package_name_version_test_impl)

def zig_packages_test_suite(name):
    unittest.suite(
        name,
        partial.make(_resolve_cell_test, size = "small"),
        partial.make(_check_cells_test, size = "small"),
        partial.make(_package_name_version_test, size = "small"),
    )
