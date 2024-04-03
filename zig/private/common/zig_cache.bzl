"""Defines utilities to handle the Zig compiler cache."""

def zig_cache_output(*, zigtoolchaininfo, args):
    """Handle the Zig compiler cache.

    Configures the local and global cache based on the given cache prefix path.
    The cache is not a Bazel managed input or output of the build action.

    Args:
      zigtoolchaininfo: ZigToolchainInfo.
      args: Args; mutable, Append the Zig cache flags to this object.
    """
    args.add_all(["--cache-dir", zigtoolchaininfo.zig_cache])
    args.add_all(["--global-cache-dir", zigtoolchaininfo.zig_cache])
