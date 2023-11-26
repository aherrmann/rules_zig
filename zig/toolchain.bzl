"Rules to declare Zig toolchains."

load(
    "//zig/private:zig_target_toolchain.bzl",
    _zig_target_toolchain = "zig_target_toolchain",
)
load(
    "//zig/private:zig_toolchain.bzl",
    _zig_toolchain = "zig_toolchain",
)

zig_toolchain = _zig_toolchain
zig_target_toolchain = _zig_target_toolchain
