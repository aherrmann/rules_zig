"""Analysis tests for rules
See https://bazel.build/rules/testing#testing-rules
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest")

def _simple_binary_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
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
