"""Extensions for bzlmod."""

load("//zig/private/bzlmod:cc_common_link.bzl", _cc_common_link = "cc_common_link")
load("//zig/private/bzlmod:zig.bzl", _zig = "zig")

zig = _zig
cc_common_link = _cc_common_link
