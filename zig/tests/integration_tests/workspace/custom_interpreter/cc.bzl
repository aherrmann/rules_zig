"""Dummy CC toolchain for custom-interpreter test.

Provides a dummy CC toolchain such that the custom_interpreter test also works
on other platforms than Linux without having to supply a proper C/C++
cross-compilation toolchain.
"""

def _cc_toolchain_config_impl(ctx):
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "cc-dummy-toolchain",
        host_system_name = "dummy",
        target_system_name = "dummy",
        target_cpu = "dummy",
        target_libc = "gnu",
        compiler = "dummy",
        abi_version = "unknown",
        abi_libc_version = "unknown",
    )

_cc_toolchain_config = rule(
    implementation = _cc_toolchain_config_impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)

def cc_config(*, name, target_compatible_with):
    _cc_toolchain_config(name = name + "_cc_config")
    native.cc_toolchain(
        name = name + "_cc_toolchain",
        toolchain_identifier = "dummy-toolchain",
        toolchain_config = ":" + name + "_cc_config",
        all_files = ":empty",
        compiler_files = ":empty",
        dwp_files = ":empty",
        linker_files = ":empty",
        objcopy_files = ":empty",
        strip_files = ":empty",
        supports_param_files = 0,
    )
    native.toolchain(
        name = name,
        target_compatible_with = target_compatible_with,
        toolchain = ":" + name + "_cc_toolchain",
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )
