"""This module implements the language-specific toolchain rule.
"""

load(
    "//zig/private:zig_toolchain.bzl",
    _ZigInfo = "ZigInfo",
    _zig_toolchain = "zig_toolchain",
)
load(
    "//zig/private:zig_target_toolchain.bzl",
    _zig_target_toolchain = "zig_target_toolchain",
)

ZigInfo = _ZigInfo
zig_toolchain = _zig_toolchain
zig_target_toolchain = _zig_target_toolchain
