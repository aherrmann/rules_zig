"""Unit tests for the `zig_package` repository rule helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private/repo:zig_package.bzl", "merge", "parse_cells")

def _record(*, kind = "zig_library", name, fixed = {}, varying = {}):
    return struct(kind = kind, name = name, fixed = fixed, varying = varying)

_FALLBACK = struct(name = "dbg", config_setting = "")
_REL = struct(name = "rel", config_setting = "rel")

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

def _merge_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (None, [_record(name = "foo", fixed = {"main": "foo.zig"}, varying = {"deps": ("const", ["a"])})]),
        merge("pkg", {"dbg": [_record(name = "foo", fixed = {"main": "foo.zig"}, varying = {"deps": ["a"]})]}, [_FALLBACK]),
        "a single cell makes every varying attr constant",
    )

    asserts.equals(
        env,
        (None, [_record(
            name = "foo",
            fixed = {"main": "foo.zig"},
            varying = {"deps": ("select", {"dbg": ["a"], "rel": ["b"]}), "import_names": ("const", {})},
        )]),
        merge(
            "pkg",
            {
                "dbg": [_record(name = "foo", fixed = {"main": "foo.zig"}, varying = {"deps": ["a"], "import_names": {}})],
                "rel": [_record(name = "foo", fixed = {"main": "foo.zig"}, varying = {"deps": ["b"], "import_names": {}})],
            },
            [_FALLBACK, _REL],
        ),
        "a differing attr becomes a select; an agreeing attr stays constant",
    )

    asserts.equals(
        env,
        ("package 'pkg' produces a different set of targets under config 'rel' than under 'dbg'", None),
        merge(
            "pkg",
            {"dbg": [_record(name = "foo")], "rel": [_record(name = "foo"), _record(name = "bar")]},
            [_FALLBACK, _REL],
        ),
        "the set of targets must be constant across configs",
    )

    asserts.equals(
        env,
        ("package 'pkg' target 'foo' has kind 'cc_library' under config 'rel' but 'zig_library' under 'dbg'", None),
        merge(
            "pkg",
            {
                "dbg": [_record(kind = "zig_library", name = "foo")],
                "rel": [_record(kind = "cc_library", name = "foo")],
            },
            [_FALLBACK, _REL],
        ),
        "a target's kind must be constant across configs",
    )

    asserts.equals(
        env,
        ("package 'pkg' target 'foo' fixed attribute 'main' varies by configuration", None),
        merge(
            "pkg",
            {
                "dbg": [_record(name = "foo", fixed = {"main": "foo.zig"})],
                "rel": [_record(name = "foo", fixed = {"main": "bar.zig"})],
            },
            [_FALLBACK, _REL],
        ),
        "a fixed attribute must be constant across configs",
    )

    return unittest.end(env)

_merge_test = unittest.make(_merge_test_impl)

def zig_package_test_suite(name):
    unittest.suite(
        name,
        partial.make(_parse_cells_test, size = "small"),
        partial.make(_merge_test, size = "small"),
    )
