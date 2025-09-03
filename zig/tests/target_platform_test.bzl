"""Analysis tests for Zig target platform configuration."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//zig/private/providers:zig_target_info.bzl", "ZigTargetInfo")
load(
    ":util.bzl",
    "assert_find_action",
    "assert_find_unique_option",
    "canonical_label",
)

_TARGET_PLATFORM = "//command_line_option:platforms"
_EXTRA_TOOLCHAINS = "//command_line_option:extra_toolchains"

_TOOLCHAIN_UNCONSTRAINED_DEFAULT_TEST = canonical_label("@//zig/tests/platforms:unconstrained_default_test_toolchain")

_TOOLCHAIN_ZIG_ONLY_X86_64_LINUX = canonical_label("@//zig/tests/platforms:zig-only-x86_64-linux_toolchain")
_PLATFORM_ZIG_ONLY_X86_64_LINUX = canonical_label("@//zig/tests/platforms:zig-only-x86_64-linux")

_PLATFORM_X86_64_LINUX = canonical_label("@//zig/tests/platforms:x86_64-linux")
_PLATFORM_X86_64_LINUX_MUSL = canonical_label("@//zig/tests/platforms:x86_64-linux-musl")
_PLATFORM_AARCH64_LINUX = canonical_label("@//zig/tests/platforms:aarch64-linux")
_PLATFORM_AARCH64_LINUX_NONE = canonical_label("@//zig/tests/platforms:aarch64-linux-none")
_PLATFORM_X86_64_WINDOWS = canonical_label("@//zig/tests/platforms:x86_64-windows")
_PLATFORM_X86_64_WINDOWS_NONE = canonical_label("@//zig/tests/platforms:x86_64-windows-none")

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
        config_settings = {
            _TARGET_PLATFORM: target,
            _EXTRA_TOOLCHAINS: _TOOLCHAIN_UNCONSTRAINED_DEFAULT_TEST,
        },
    )

_target_platform_x86_64_linux_test = _define_target_platform_test(_PLATFORM_X86_64_LINUX, "x86_64-linux-gnu.2.17")
_target_platform_x86_64_linux_musl_test = _define_target_platform_test(_PLATFORM_X86_64_LINUX_MUSL, "x86_64-linux-musl")
_target_platform_aarch64_linux_test = _define_target_platform_test(_PLATFORM_AARCH64_LINUX, "aarch64-linux-gnu.2.17")
_target_platform_aarch64_linux_none_test = _define_target_platform_test(_PLATFORM_AARCH64_LINUX_NONE, "aarch64-linux-none")
_target_platform_x86_64_windows_test = _define_target_platform_test(_PLATFORM_X86_64_WINDOWS, "x86_64-windows-gnu")
_target_platform_x86_64_windows_none_test = _define_target_platform_test(_PLATFORM_X86_64_WINDOWS_NONE, "x86_64-windows-none")

def _define_build_target_platform_test(mnemonic, target, option):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)

        action = assert_find_action(env, mnemonic)
        target_option = assert_find_unique_option(env, "-target", action.argv)
        asserts.equals(env, option, target_option)

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {
            _TARGET_PLATFORM: target,
            _EXTRA_TOOLCHAINS: _TOOLCHAIN_UNCONSTRAINED_DEFAULT_TEST,
        },
    )

_build_exe_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_X86_64_LINUX, "x86_64-linux-gnu.2.17")
_build_exe_target_platform_x86_64_linux_musl_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_X86_64_LINUX_MUSL, "x86_64-linux-musl")
_build_exe_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_AARCH64_LINUX, "aarch64-linux-gnu.2.17")
_build_exe_target_platform_aarch64_linux_none_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_AARCH64_LINUX_NONE, "aarch64-linux-none")
_build_exe_target_platform_x86_64_windows_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_X86_64_WINDOWS, "x86_64-windows-gnu")
_build_exe_target_platform_x86_64_windows_none_test = _define_build_target_platform_test("ZigBuildExe", _PLATFORM_X86_64_WINDOWS_NONE, "x86_64-windows-none")

_build_static_lib_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildStaticLib", _PLATFORM_X86_64_LINUX, "x86_64-linux-gnu.2.17")
_build_static_lib_target_platform_x86_64_linux_musl_test = _define_build_target_platform_test("ZigBuildStaticLib", _PLATFORM_X86_64_LINUX_MUSL, "x86_64-linux-musl")
_build_static_lib_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildStaticLib", _PLATFORM_AARCH64_LINUX, "aarch64-linux-gnu.2.17")
_build_static_lib_target_platform_aarch64_linux_none_test = _define_build_target_platform_test("ZigBuildStaticLib", _PLATFORM_AARCH64_LINUX_NONE, "aarch64-linux-none")
_build_static_lib_target_platform_x86_64_windows_test = _define_build_target_platform_test("ZigBuildStaticLib", _PLATFORM_X86_64_WINDOWS, "x86_64-windows-gnu")
_build_static_lib_target_platform_x86_64_windows_none_test = _define_build_target_platform_test("ZigBuildStaticLib", _PLATFORM_X86_64_WINDOWS_NONE, "x86_64-windows-none")

_build_shared_lib_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_X86_64_LINUX, "x86_64-linux-gnu.2.17")
_build_shared_lib_target_platform_x86_64_linux_musl_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_X86_64_LINUX_MUSL, "x86_64-linux-musl")
_build_shared_lib_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_AARCH64_LINUX, "aarch64-linux-gnu.2.17")
_build_shared_lib_target_platform_aarch64_linux_none_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_AARCH64_LINUX_NONE, "aarch64-linux-none")
_build_shared_lib_target_platform_x86_64_windows_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_X86_64_WINDOWS, "x86_64-windows-gnu")
_build_shared_lib_target_platform_x86_64_windows_none_test = _define_build_target_platform_test("ZigBuildSharedLib", _PLATFORM_X86_64_WINDOWS_NONE, "x86_64-windows-none")

_build_test_target_platform_x86_64_linux_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_X86_64_LINUX, "x86_64-linux-gnu.2.17")
_build_test_target_platform_x86_64_linux_musl_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_X86_64_LINUX_MUSL, "x86_64-linux-musl")
_build_test_target_platform_aarch64_linux_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_AARCH64_LINUX, "aarch64-linux-gnu.2.17")
_build_test_target_platform_aarch64_linux_none_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_AARCH64_LINUX_NONE, "aarch64-linux-none")
_build_test_target_platform_x86_64_windows_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_X86_64_WINDOWS, "x86_64-windows-gnu")
_build_test_target_platform_x86_64_windows_none_test = _define_build_target_platform_test("ZigBuildTest", _PLATFORM_X86_64_WINDOWS_NONE, "x86_64-windows-none")

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
        config_settings = {
            _TARGET_PLATFORM: target,
            _EXTRA_TOOLCHAINS: _TOOLCHAIN_UNCONSTRAINED_DEFAULT_TEST,
        },
    )

_exe_file_extension_x86_64_linux_test = _define_file_extension_test(_PLATFORM_X86_64_LINUX, "")
_exe_file_extension_x86_64_windows_test = _define_file_extension_test(_PLATFORM_X86_64_WINDOWS, ".exe")

_lib_file_extension_x86_64_linux_test = _define_file_extension_test(_PLATFORM_X86_64_LINUX, ".a", basename_pattern = "lib%s")
_lib_file_extension_x86_64_windows_test = _define_file_extension_test(_PLATFORM_X86_64_WINDOWS, ".lib")

_shared_lib_file_extension_x86_64_linux_test = _define_file_extension_test(_PLATFORM_X86_64_LINUX, ".so", basename_pattern = "lib%s")
_shared_lib_file_extension_x86_64_windows_test = _define_file_extension_test(_PLATFORM_X86_64_WINDOWS, ".dll")

_test_file_extension_x86_64_linux_test = _define_file_extension_test(_PLATFORM_X86_64_LINUX, "")
_test_file_extension_x86_64_windows_test = _define_file_extension_test(_PLATFORM_X86_64_WINDOWS, ".exe")

def _define_cc_info_test(target, cc_expected):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)
        target = analysistest.target_under_test(env)

        if cc_expected:
            asserts.true(env, CcInfo in target, "Expected CcInfo.")
        else:
            asserts.false(env, CcInfo in target, "Expected no CcInfo.")

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings =
            {_EXTRA_TOOLCHAINS: ",".join([
                _TOOLCHAIN_ZIG_ONLY_X86_64_LINUX,
                _TOOLCHAIN_UNCONSTRAINED_DEFAULT_TEST,
            ])} |
            {_TARGET_PLATFORM: target} if target else {},
    )

_cc_info_host_test = _define_cc_info_test(None, True)
_cc_info_zig_only_test = _define_cc_info_test(_PLATFORM_ZIG_ONLY_X86_64_LINUX, False)

def target_platform_test_suite(name):
    unittest.suite(
        name,
        # Test Zig target platform on the resolved toolchain target
        partial.make(_target_platform_x86_64_linux_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        partial.make(_target_platform_x86_64_linux_musl_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        partial.make(_target_platform_aarch64_linux_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        partial.make(_target_platform_aarch64_linux_none_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        partial.make(_target_platform_x86_64_windows_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        partial.make(_target_platform_x86_64_windows_none_test, target_under_test = "//zig/target:resolved_toolchain", size = "small"),
        # Test Zig target plaform on a binary target
        partial.make(_build_exe_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_target_platform_x86_64_linux_musl_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_target_platform_aarch64_linux_none_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_target_platform_x86_64_windows_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_build_exe_target_platform_x86_64_windows_none_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_exe_file_extension_x86_64_linux_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        partial.make(_exe_file_extension_x86_64_windows_test, target_under_test = "//zig/tests/simple-binary:binary", size = "small"),
        # Test Zig target plaform on a library target
        partial.make(_build_static_lib_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_target_platform_x86_64_linux_musl_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_target_platform_aarch64_linux_none_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_target_platform_x86_64_windows_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_build_static_lib_target_platform_x86_64_windows_none_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_lib_file_extension_x86_64_linux_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        partial.make(_lib_file_extension_x86_64_windows_test, target_under_test = "//zig/tests/simple-library:library", size = "small"),
        # Test Zig target plaform on a shared library target
        partial.make(_build_shared_lib_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_target_platform_x86_64_linux_musl_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_target_platform_aarch64_linux_none_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_target_platform_x86_64_windows_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_build_shared_lib_target_platform_x86_64_windows_none_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_shared_lib_file_extension_x86_64_linux_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_shared_lib_file_extension_x86_64_windows_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        # Test Zig target plaform on a test target
        partial.make(_build_test_target_platform_x86_64_linux_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_target_platform_x86_64_linux_musl_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_target_platform_aarch64_linux_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_target_platform_aarch64_linux_none_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_target_platform_x86_64_windows_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_build_test_target_platform_x86_64_windows_none_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_test_file_extension_x86_64_linux_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        partial.make(_test_file_extension_x86_64_windows_test, target_under_test = "//zig/tests/simple-test:test", size = "small"),
        # Test optional cc-toolchain dependency
        partial.make(_cc_info_host_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
        partial.make(_cc_info_zig_only_test, target_under_test = "//zig/tests/simple-shared-library:shared", size = "small"),
    )
