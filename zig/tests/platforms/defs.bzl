"""Helper rules and functions for platform tests."""

empty_toolchain = rule(
    implementation = lambda ctx: platform_common.ToolchainInfo(),
)
