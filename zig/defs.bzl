"Public API re-exports"

load("//zig/private:zig_binary.bzl", _zig_binary = "zig_binary")
load("//zig/private:zig_package.bzl", _zig_package = "zig_package")

zig_binary = _zig_binary
zig_package = _zig_package
