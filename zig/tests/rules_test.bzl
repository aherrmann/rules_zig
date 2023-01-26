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

    return analysistest.end(env)

_simple_binary_test = analysistest.make(_simple_binary_test_impl)

def _test_simple_binary(name):
    _simple_binary_test(
        name = name,
        target_under_test = "//zig/tests/simple-binary:binary",
    )

def rules_test_suite(name):
    _test_simple_binary(name = "simple_binary_test")
    native.test_suite(
        name = name,
        tests = [
            ":simple_binary_test",
        ],
    )
