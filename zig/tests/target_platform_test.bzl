"""Analysis tests for Zig target platform configuration."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//zig/private/providers:zig_target_info.bzl", "ZigTargetInfo")
load(
    ":util.bzl",
    "assert_find_action",
    "assert_find_unique_option",
    "canonical_label",
)

_TARGET_PLATFORM = "//command_line_option:platforms"

_PLATFORM_X86_64_LINUX = canonical_label("@//zig/tests/platforms:x86_64-linux")
_PLATFORM_AARCH64_LINUX = canonical_label("@//zig/tests/platforms:aarch64-linux")
_PLATFORM_X86_64_WINDOWS = canonical_label("@//zig/tests/platforms:x86_64-windows")

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
_target_platform_x86_64_windows_test = _define_target_platform_test(_PLATFORM_X86_64_WINDOWS, "x86_64-windows")

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
_build_exe_target_platform_x86_64_windows_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_X86_64_WINDOWS, "x86_64-windows")

_build_lib_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildLib", _PLATFORM_X86_64_LINUX, "x86_64-linux")
_build_lib_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildLib", _PLATFORM_AARCH64_LINUX, "aarch64-linux")
_build_lib_target_platform_x86_64_windows_test = _define_build_target_platform_test("ZigBuildLib", _PLATFORM_X86_64_WINDOWS, "x86_64-windows")

_build_shared_lib_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_X86_64_LINUX, "x86_64-linux")
_build_shared_lib_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_AARCH64_LINUX, "aarch64-linux")
_build_shared_lib_target_platform_x86_64_windows_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_X86_64_WINDOWS, "x86_64-windows")

_build_test_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_X86_64_LINUX, "x86_64-linux")
_build_test_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_AARCH64_LINUX, "aarch64-linux")
_build_test_target_platform_x86_64_windows_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_X86_64_WINDOWS, "x86_64-windows")

def _define_file_extension_test(target, extension, basename_pattern = "%s"):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)
        target = analysistest.target_under_test(env)

        files = target.files.to_list()
        asserts.true(env, len(files) > 0, "Expected at least one output.")

        out_base, out_ext = paths.split_extension(paths.basename(files[0].path))
        asserts.equals(env, basename_pattern % target.label.name, out_base, "Expected output basename to match target name.")
        asserts.equals(env, extension, out_ext, "Output extension mismatch.")

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {_TARGET_PLATFORM: target},
    )

_exe_file_extension_x86_64_linux_test = _define_file_extension_test(_PLATFORM_X86_64_LINUX, "")
_exe_file_extension_x86_64_windows_test = _define_file_extension_test(_PLATFORM_X86_64_WINDOWS, ".exe")

_lib_file_extension_x86_64_linux_test = _define_file_extension_test(_PLATFORM_X86_64_LINUX, ".a", basename_pattern = "lib%s")
_lib_file_extension_x86_64_windows_test = _define_file_extension_test(_PLATFORM_X86_64_WINDOWS, ".lib")

_shared_lib_file_extension_x86_64_linux_test = _define_file_extension_test(_PLATFORM_X86_64_LINUX, ".so", basename_pattern = "lib%s")
_shared_lib_file_extension_x86_64_windows_test = _define_file_extension_test(_PLATFORM_X86_64_WINDOWS, ".dll")

_test_file_extension_x86_64_linux_test = _define_file_extension_test(_PLATFORM_X86_64_LINUX, "")
_test_file_extension_x86_64_windows_test = _define_file_extension_test(_PLATFORM_X86_64_WINDOWS, ".exe")

def target_platform_test_suite(name):
    unittest.suite(
        name,
        # Test Zig target platform on the resolved toolchain target
        partial.make(_target_platform_x86_64_linux_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        partial.make(_target_platform_aarch64_linux_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        partial.make(_target_platform_x86_64_windows_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        # Test Zig target plaform on a binary target
        partial.make(_build_exe_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_target_platform_x86_64_windows_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_exe_file_extension_x86_64_linux_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_exe_file_extension_x86_64_windows_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        # Test Zig target plaform on a library target
        partial.make(_build_lib_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_lib_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_lib_target_platform_x86_64_windows_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_lib_file_extension_x86_64_linux_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_lib_file_extension_x86_64_windows_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        # Test Zig target plaform on a shared library target
        partial.make(_build_shared_lib_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_target_platform_x86_64_windows_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_shared_lib_file_extension_x86_64_linux_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_shared_lib_file_extension_x86_64_windows_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        # Test Zig target plaform on a test target
        partial.make(_build_test_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_target_platform_x86_64_windows_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_test_file_extension_x86_64_linux_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_test_file_extension_x86_64_windows_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
    )
