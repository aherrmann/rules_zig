"""Utility functions for interacting with CC toolchains."""

load("@rules_cc//cc:find_cc_toolchain.bzl", find_rules_cc_toolchain = "find_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def need_translate_c(cc_info):
    return cc_info.compilation_context and (cc_info.compilation_context.headers or cc_info.compilation_context.defines)

def find_cc_toolchain(ctx, *, mandatory):
    """Extracts a CcToolchain from the current target's context

    Args:
        ctx (ctx): The current target's rule context object
        mandatory (bool): Whether the toolchain is mandatory

    Returns:
        tuple: A tuple of (CcToolchain, FeatureConfiguration)
    """
    cc_toolchain = find_rules_cc_toolchain(ctx, mandatory = mandatory)
    if cc_toolchain == None:
        return None, None

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    return cc_toolchain, feature_configuration
