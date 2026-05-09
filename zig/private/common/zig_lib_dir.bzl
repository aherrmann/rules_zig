"""Defines utilities to handle the Zig library directory."""

load("//zig/private/providers:zig_toolchain_info.bzl", "zig_toolchain_lib_dir")

def zig_lib_dir(*, zigtoolchaininfo, args):
    """Handle the Zig library directory.

    Sets the Zig library directory flag.
    Appends to the arguments object.

    Args:
      zigtoolchaininfo: ZigToolchainInfo.
      args: Args; mutable, Append the Zig cache flags to this object.
    """
    args.add("--zig-lib-dir")
    args.add(zig_toolchain_lib_dir(zigtoolchaininfo))
