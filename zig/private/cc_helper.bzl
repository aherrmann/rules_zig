"""Utility functions for interacting with CC toolchains."""

def need_translate_c(cc_info):
    return cc_info.compilation_context and (cc_info.compilation_context.headers or cc_info.compilation_context.defines)
