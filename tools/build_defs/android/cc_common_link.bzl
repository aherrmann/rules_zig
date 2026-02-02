"""A module that exposes private APIs of cc_common.link.

See https://github.com/bazelbuild/bazel/pull/23838#issuecomment-3756393397.
"""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def cc_common_link(*args, **kwargs):
    return cc_common.link(*args, **kwargs)
