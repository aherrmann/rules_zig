"""Unit tests for Zig toolchain header module."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load(
    "@bazel_skylib//lib:unittest.bzl",
    "analysistest",
    "asserts",
    "unittest",
)
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//zig/private:zig_toolchain_header.bzl", "max_int_alignment")
load(":util.bzl", "canonical_label")

def _max_int_alignment_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        8,
        max_int_alignment("arm"),
    )

    asserts.equals(
        env,
        16,
        max_int_alignment("x86_64"),
    )

    return unittest.end(env)

_max_int_alignment_test = unittest.make(
    _max_int_alignment_test_impl,
)

_TARGET_PLATFORM = "//command_line_option:platforms"
_EXTRA_TOOLCHAINS = "//command_line_option:extra_toolchains"

_TOOLCHAIN_X86_64_WINDOWS_MSVC = canonical_label("@//zig/tests/platforms:x86_64-windows-msvc_toolchain")

_PLATFORM_PPC_LINUX_MUSL = canonical_label("@//zig/tests/platforms:ppc-linux-musl")
_PLATFORM_X86_64_WINDOWS_MSVC = canonical_label("@//zig/tests/platforms:x86_64-windows-msvc")

def _define_zig_header_defines_test(platform, alignment, msvc):
    def _test_impl(ctx):
        env = analysistest.begin(ctx)
        target = analysistest.target_under_test(env)
        cc = target[CcInfo]

        asserts.true(
            env,
            any([
                define == "ZIG_TARGET_MAX_INT_ALIGNMENT={}".format(alignment)
                for define in cc.compilation_context.defines.to_list()
            ]),
            "ZIG_TARGET_MAX_INT_ALIGNMENT should be defined correctly",
        )

        if msvc:
            asserts.true(
                env,
                any([
                    define == "ZIG_TARGET_ABI_MSVC"
                    for define in cc.compilation_context.defines.to_list()
                ]),
                "ZIG_TARGET_ABI_MSVC should be defined",
            )
        else:
            asserts.false(
                env,
                any([
                    define == "ZIG_TARGET_ABI_MSVC"
                    for define in cc.compilation_context.defines.to_list()
                ]),
                "ZIG_TARGET_ABI_MSVC should not be defined",
            )

        return analysistest.end(env)

    return analysistest.make(
        _test_impl,
        config_settings = {
            _TARGET_PLATFORM: platform,
            _EXTRA_TOOLCHAINS: _TOOLCHAIN_X86_64_WINDOWS_MSVC,
        },
    )

_zig_header_defines_ppc_linux_musl_test = _define_zig_header_defines_test(_PLATFORM_PPC_LINUX_MUSL, 8, False)
_zig_header_defines_x86_64_windows_msvc_test = _define_zig_header_defines_test(_PLATFORM_X86_64_WINDOWS_MSVC, 16, True)

def _zig_header_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    cc = target[CcInfo]

    asserts.true(
        env,
        any([
            define.startswith("ZIG_TARGET_MAX_INT_ALIGNMENT")
            for define in cc.compilation_context.defines.to_list()
        ]),
        "ZIG_TARGET_MAX_INT_ALIGNMENT should be defined",
    )

    return analysistest.end(env)

_zig_header_test = analysistest.make(_zig_header_test_impl)

def _test_zig_header(name):
    _zig_header_test(
        name = name,
        target_under_test = "@rules_zig//zig/lib:zig_header",
        size = "small",
    )

def toolchain_header_test_suite(name):
    unittest.suite(
        name,
        partial.make(_max_int_alignment_test, size = "small"),
        partial.make(_zig_header_defines_ppc_linux_musl_test, target_under_test = "@rules_zig//zig/lib:zig_header", size = "small"),
        partial.make(_zig_header_defines_x86_64_windows_msvc_test, target_under_test = "@rules_zig//zig/lib:zig_header", size = "small"),
        partial.make(_test_zig_header),
    )
