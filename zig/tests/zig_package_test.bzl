"""Unit tests for the `zig_package` repository rule helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private/repo:zig_package.bzl", "parse_cells")

def _parse_cells_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (None, [struct(name = "", zig_options = [], config_setting = "")]),
        parse_cells(""),
        "no matrix yields a single host fallback cell",
    )

    dbg = {"name": "dbg", "zig_options": ["-Doptimize=Debug"], "config_setting": ""}
    rel = {"name": "rel", "zig_options": ["-Doptimize=ReleaseFast"], "config_setting": "rel"}
    asserts.equals(
        env,
        (None, [
            struct(name = "dbg", zig_options = ["-Doptimize=Debug"], config_setting = ""),
            struct(name = "rel", zig_options = ["-Doptimize=ReleaseFast"], config_setting = "rel"),
        ]),
        parse_cells(json.encode([rel, dbg])),
        "the fallback cell is ordered first",
    )

    asserts.equals(
        env,
        ("expected exactly one fallback cell, found 0", None),
        parse_cells(json.encode([rel])),
        "a matrix must have a fallback",
    )

    asserts.equals(
        env,
        ("expected exactly one fallback cell, found 2", None),
        parse_cells(json.encode([dbg, dict(rel, config_setting = "")])),
        "a matrix must have only one fallback",
    )

    return unittest.end(env)

_parse_cells_test = unittest.make(_parse_cells_test_impl)

def zig_package_test_suite(name):
    unittest.suite(
        name,
        partial.make(_parse_cells_test, size = "small"),
    )
