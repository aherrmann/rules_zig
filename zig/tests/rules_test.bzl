"""Analysis tests for rules
See https://bazel.build/rules/testing#testing-rules
"""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

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
    )

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
    )

def rules_test_suite(name):
    _test_simple_binary(name = "simple_binary_test")
    _test_multiple_sources_binary(name = "multiple_sources_binary_test")
    native.test_suite(
        name = name,
        tests = [
            ":simple_binary_test",
            ":multiple_sources_binary_test",
        ],
    )
