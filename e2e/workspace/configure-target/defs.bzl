"""Helper rules and functions for target configuration tests."""

empty_toolchain = rule(
    implementation = lambda ctx: platform_common.ToolchainInfo(),
)
