"""Unit tests for the `zig_package` repository rule helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private/repo:zig_package.bzl", "merge", "parse_cells", "render", "render_attr")

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

def _render_attr_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        '["a"]',
        render_attr({}, ("const", ["a"]), [_FALLBACK]),
        "a constant attribute renders without select",
    )

    asserts.equals(
        env,
        """\
select({
    "@x//config:cfg_rel": ["b"],
    "//conditions:default": ["a"],
})""",
        render_attr({"rel": "@x//config:cfg_rel"}, ("select", {"dbg": ["a"], "rel": ["b"]}), [_FALLBACK, _REL]),
        "a select renders non-fallback cells, then the fallback as //conditions:default",
    )

    return unittest.end(env)

_render_attr_test = unittest.make(_render_attr_test_impl)

def _render_test_impl(ctx):
    env = unittest.begin(ctx)

    out = render(
        {},
        [_record(name = "foo", fixed = {"main": "foo.zig"}, varying = {"deps": ("const", ["a"]), "import_names": ("const", {})})],
        [_FALLBACK],
    )
    asserts.true(env, 'load("@rules_zig//zig:defs.bzl", "zig_library")' in out, "loads zig_library")
    asserts.true(env, 'name = "foo"' in out, "emits the target")
    asserts.true(env, 'deps = ["a"]' in out, "inlines a constant attribute")
    asserts.true(env, "@rules_cc" not in out, "omits the cc_library load with no C targets")

    out = render(
        {},
        [
            _record(
                kind = "zig_library_subtree",
                name = "vendor/foo",
                fixed = {"import_name": "foo", "main": "vendor/foo/foo.zig", "subpath": "vendor/foo"},
                varying = {"deps": ("const", [":bar"]), "import_names": ("const", {})},
            ),
            _record(
                kind = "cc_library",
                name = "z.cinc.0",
                fixed = {"header_globs": ["c/**/*.h"]},
                varying = {"srcs": ("const", ["c/z.c"]), "copts": ("const", ["-DZ"]), "includes": ("const", ["c"])},
            ),
            _record(
                kind = "cc_library_group",
                name = "z.cinc",
                varying = {"deps": ("const", [":z.cinc.0"])},
            ),
        ],
        [_FALLBACK],
    )
    asserts.true(env, 'load("@rules_cc//cc:defs.bzl", "cc_library")' in out, "loads cc_library when C targets are present")
    asserts.true(env, 'name = "vendor/foo"' in out, "emits the subtree library scoped by sub-path")
    asserts.true(env, 'import_name = "foo"' in out, "the subtree library keeps the module's import name")
    asserts.true(env, 'srcs = glob(["vendor/foo/**/*.zig"], exclude = ["vendor/foo/foo.zig"])' in out, "globs the subtree's sources")
    asserts.true(env, 'srcs = ["c/z.c"]' in out, "emits the cc_library sources")
    asserts.true(env, 'hdrs = glob(["c/**/*.h"], allow_empty = True)' in out, "globs the cc_library headers")
    asserts.true(env, 'deps = [":z.cinc.0"]' in out, "the cc_library group depends on its source groups")

    return unittest.end(env)

_render_test = unittest.make(_render_test_impl)

def zig_package_test_suite(name):
    unittest.suite(
        name,
        partial.make(_parse_cells_test, size = "small"),
        partial.make(_merge_test, size = "small"),
        partial.make(_render_attr_test, size = "small"),
        partial.make(_render_test, size = "small"),
    )
