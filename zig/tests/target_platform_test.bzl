"""Analysis tests for Zig target platform configuration."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("@bazel_skylib//lib:partial.bzl", "partial")
load("//zig/private/providers:zig_target_info.bzl", "ZigTargetInfo")
load(
    ":util.bzl",
    "assert_find_action",
    "assert_find_unique_option",
)

_TARGET_PLATFORM = "//command_line_option:platforms"

# TODO[AH] Canonicalize these labels (`str(Label(...))`) for `bzlmod` support.
# Note, that canonicalization is not compatible with Bazel 5.3.2, where it will
# strip the requried `@` prefix.
_PLATFORM_X86_64_LINUX = "@//zig/tests/platforms:x86_64-linux"
_PLATFORM_AARCH64_LINUX = "@//zig/tests/platforms:aarch64-linux"

def _define_target_platform_test(target, option):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        targetinfo = analysistest.target_under_test(env)[ZigTargetInfo]
        asserts.equals(env, option, targetinfo.target)

        target_option = assert_find_unique_option(env, "-target", targetinfo.args)
        asserts.equals(env, option, target_option)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_TARGET_PLATFORM: target},
    )

_target_platform_x86_64_linux_test = _define_target_platform_test(_PLATFORM_X86_64_LINUX, "x86_64-linux")
_target_platform_aarch64_linux_test = _define_target_platform_test(_PLATFORM_AARCH64_LINUX, "aarch64-linux")
# TODO[AH] Test another operating system as well

def _define_build_target_platform_test(mnemonic, target, option):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        action = assert_find_action(env, mnemonic)
        target_option = assert_find_unique_option(env, "-target", action.argv)
        asserts.equals(env, option, target_option)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_TARGET_PLATFORM: target},
    )

_build_exe_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_X86_64_LINUX, "x86_64-linux")
_build_exe_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_AARCH64_LINUX, "aarch64-linux")
# TODO[AH] Test another operating system as well

_build_lib_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildLib", _PLATFORM_X86_64_LINUX, "x86_64-linux")
_build_lib_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildLib", _PLATFORM_AARCH64_LINUX, "aarch64-linux")
# TODO[AH] Test another operating system as well

_build_test_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_X86_64_LINUX, "x86_64-linux")
_build_test_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_AARCH64_LINUX, "aarch64-linux")
# TODO[AH] Test another operating system as well

def target_platform_test_suite(name):
    unittest.suite(
        name,
        # Test Zig target platform on the resolved toolchain target
        partial.make(_target_platform_x86_64_linux_test, target_under_test = "//zig/target:resolved_toolchain"),
        partial.make(_target_platform_aarch64_linux_test, target_under_test = "//zig/target:resolved_toolchain"),
        # TODO[AH] Test another operating system as well
        # Test Zig target plaform on a binary target
        partial.make(_build_exe_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-binary:binary"),
        partial.make(_build_exe_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-binary:binary"),
        # TODO[AH] Test another operating system as well
        # Test Zig target plaform on a library target
        partial.make(_build_lib_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-library:library"),
        partial.make(_build_lib_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-library:library"),
        # TODO[AH] Test another operating system as well
        # Test Zig target plaform on a test target
        partial.make(_build_test_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-test:test"),
        partial.make(_build_test_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-test:test"),
        # TODO[AH] Test another operating system as well
    )