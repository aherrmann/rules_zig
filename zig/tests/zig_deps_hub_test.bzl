"""Unit tests for the `zig_deps` hub repository rule helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//zig/private/repo:zig_deps_hub.bzl", "render_config_groups")

def _render_config_groups_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "",
        render_config_groups([]),
        "no groups renders nothing",
    )

    out = render_config_groups([{"name": "rel", "select_on": ["@platforms//os:linux", "//zig/config/mode:release_fast"]}])
    asserts.true(env, "load(\"@bazel_skylib//lib:selects.bzl\", \"selects\")" in out, "loads selects")
    asserts.true(env, "name = \"cfg_rel\"" in out, "names the group cfg_<name>")
    asserts.true(env, "match_all = [" in out, "matches all conditions")
    asserts.true(env, "\"@platforms//os:linux\"" in out, "includes the os condition")
    asserts.true(env, "\"//zig/config/mode:release_fast\"" in out, "includes the mode condition")

    return unittest.end(env)

_render_config_groups_test = unittest.make(_render_config_groups_test_impl)

def zig_deps_hub_test_suite(name):
    unittest.suite(
        name,
        partial.make(_render_config_groups_test, size = "small"),
    )
