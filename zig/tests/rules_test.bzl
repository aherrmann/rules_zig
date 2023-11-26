"""Analysis tests for rules
See https://bazel.build/rules/testing#testing-rules
"""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(
    ":util.bzl",
    "assert_find_unique_surrounded_arguments",
    "assert_flag_unset",
)

def _simple_binary_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    default = target[DefaultInfo]

    executable = default.files_to_run.executable
    asserts.true(executable != None, "zig_binary should produce an executable.")
    asserts.true(sets.contains(sets.make(default.files.to_list()), executable), "zig_binary should return the executable as an output.")
    asserts.true(sets.contains(sets.make(default.default_runfiles.files.to_list()), executable), "zig_binary should return the executable in the runfiles.")

    build = [
        action
        for action in analysistest.target_actions(env)
        if action.mnemonic == "ZigBuildExe"
    ]
    asserts.equals(env, 1, len(build), "zig_binary should generate one ZigBuildExe action.")
    build = build[0]
    asserts.true(sets.contains(sets.make(build.outputs.to_list()), executable), "zig_binary should generate a ZigBuildExe action that generates the binary.")

    return analysistest.end(env)

_simple_binary_test = analysistest.make(_simple_binary_test_impl)

def _test_simple_binary(name):
    _simple_binary_test(
        name = name,
        target_under_test = "//zig/tests/simple-binary:binary",
        size = "small",
    )
    return [":" + name]

def _multiple_sources_binary_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    default = target[DefaultInfo]

    executable = default.files_to_run.executable
    main = ctx.file.main

    build = [
        action
        for action in analysistest.target_actions(env)
        if action.mnemonic == "ZigBuildExe"
    ]
    asserts.equals(env, 1, len(build), "zig_binary should generate one ZigBuildExe action.")
    build = build[0]

    # The position in the action input and output matters for the progress_message.
    asserts.equals(env, main, build.inputs.to_list()[0], "the main source should be the first input.")
    asserts.equals(env, executable, build.outputs.to_list()[0], "the binary should be the first output.")

    return analysistest.end(env)

_multiple_sources_binary_test = analysistest.make(
    _multiple_sources_binary_test_impl,
    attrs = {
        "main": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
    },
)

def _test_multiple_sources_binary(name):
    _multiple_sources_binary_test(
        name = name,
        target_under_test = "//zig/tests/multiple-sources-binary:binary",
        main = "//zig/tests/multiple-sources-binary:main.zig",
        size = "small",
    )
    return [":" + name]

def _package_binary_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    default = target[DefaultInfo]

    executable = default.files_to_run.executable
    main = ctx.file.main

    build = [
        action
        for action in analysistest.target_actions(env)
        if action.mnemonic == "ZigBuildExe"
    ]
    asserts.equals(env, 1, len(build), "zig_binary should generate one ZigBuildExe action.")
    build = build[0]

    # The position in the action input and output matters for the progress_message.
    asserts.equals(env, main, build.inputs.to_list()[0], "the main source should be the first input.")
    asserts.equals(env, executable, build.outputs.to_list()[0], "the binary should be the first output.")

    return analysistest.end(env)

_package_binary_test = analysistest.make(
    _package_binary_test_impl,
    attrs = {
        "main": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
    },
)

def _test_package_binary(name):
    _package_binary_test(
        name = name,
        target_under_test = "//zig/tests/package-binary:binary",
        main = "//zig/tests/package-binary:main.zig",
        size = "small",
    )
    return [":" + name]

def _c_sources_binary_test_impl(ctx):
    env = analysistest.begin(ctx)

    csrcs = ctx.files.csrcs
    copts = ctx.attr.copts

    build = [
        action
        for action in analysistest.target_actions(env)
        if action.mnemonic == "ZigBuildExe"
    ]
    asserts.equals(env, 1, len(build), "zig_binary should generate one ZigBuildExe action.")
    build = build[0]

    for csrc in csrcs:
        asserts.true(
            env,
            sets.contains(sets.make(build.argv), csrc.path),
            "ZigBuildExe argv should contain C source file " + csrc.path,
        )

    if copts:
        build_copts = assert_find_unique_surrounded_arguments(env, "-cflags", "--", build.argv)
        asserts.equals(env, copts, build_copts, "C compiler flags did not match expectations.")
    else:
        assert_flag_unset(env, "-cflags", build.argv)

    return analysistest.end(env)

_c_sources_binary_test = analysistest.make(
    _c_sources_binary_test_impl,
    attrs = {
        "csrcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "copts": attr.string_list(
            mandatory = False,
        ),
    },
)

def _test_c_sources_binary(name):
    _c_sources_binary_test(
        name = name + "_with_copts",
        target_under_test = "//zig/tests/c-sources-binary:with-copts",
        csrcs = [
            "//zig/tests/c-sources-binary:symbol_a.c",
            "//zig/tests/c-sources-binary:symbol_b.c",
        ],
        copts = ["-DNUMBER_A=1", "-DNUMBER_B=2"],
        size = "small",
    )
    _c_sources_binary_test(
        name = name + "_without_copts",
        target_under_test = "//zig/tests/c-sources-binary:without-copts",
        csrcs = [
            "//zig/tests/c-sources-binary:symbol_a.c",
            "//zig/tests/c-sources-binary:symbol_b.c",
        ],
        copts = [],
        size = "small",
    )
    return [":" + name + "_with_copts", ":" + name + "_without_copts"]

def rules_test_suite(name):
    """Generate test suite and test targets for common rule analysis tests.

    Args:
      name: String, a unique name for the test-suite target.
    """
    tests = []
    tests += _test_simple_binary(name = "simple_binary_test")
    tests += _test_multiple_sources_binary(name = "multiple_sources_binary_test")
    tests += _test_package_binary(name = "package_binary_test")
    tests += _test_c_sources_binary(name = "c_sources_binary_test")
    native.test_suite(
        name = name,
        tests = tests,
    )
