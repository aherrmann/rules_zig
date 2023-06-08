"""Defines utilities to handle the Zig library directory."""

def zig_lib_dir(*, zigtoolchaininfo, args):
    """Handle the Zig library directory.

    Sets the Zig library directory flag.
    Appends to the arguments object.

    Args:
      zigtoolchaininfo: ZigToolchainInfo.
      args: Args; mutable, Append the Zig cache flags to this object.
    """
    args.add_all(["--zig-lib-dir", zigtoolchaininfo.zig_lib_path])
