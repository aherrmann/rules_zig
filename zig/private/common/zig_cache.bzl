"""Defines utilities to handle the Zig compiler cache."""

VAR_CACHE_PREFIX = "RULES_ZIG_CACHE_PREFIX"
VAR_CACHE_PREFIX_LINUX = "RULES_ZIG_CACHE_PREFIX_LINUX"
VAR_CACHE_PREFIX_MACOS = "RULES_ZIG_CACHE_PREFIX_MACOS"
VAR_CACHE_PREFIX_WINDOWS = "RULES_ZIG_CACHE_PREFIX_WINDOWS"

DEFAULT_CACHE_PREFIX = "/tmp/zig-cache"
DEFAULT_CACHE_PREFIX_LINUX = "/tmp/zig-cache"
DEFAULT_CACHE_PREFIX_MACOS = "/var/tmp/zig-cache"
DEFAULT_CACHE_PREFIX_WINDOWS = "C:\\Temp\\zig-cache"

def env_zig_cache_prefix(environ, platform):
    """Determine the appropriate Zig cache prefix for the given platform.

    Args:
      environ: dict, The environment variables.
      platform: string, The name of the toolchain execution platform.

    Returns:
      The Zig cache prefix path.
    """
    if platform.find("linux") != -1:
        cache_prefix = environ.get(VAR_CACHE_PREFIX_LINUX, environ.get(VAR_CACHE_PREFIX, DEFAULT_CACHE_PREFIX_LINUX))
    elif platform.find("macos") != -1:
        cache_prefix = environ.get(VAR_CACHE_PREFIX_MACOS, environ.get(VAR_CACHE_PREFIX, DEFAULT_CACHE_PREFIX_MACOS))
    elif platform.find("windows") != -1:
        cache_prefix = environ.get(VAR_CACHE_PREFIX_WINDOWS, environ.get(VAR_CACHE_PREFIX, DEFAULT_CACHE_PREFIX_WINDOWS))
    else:
        cache_prefix = environ.get(VAR_CACHE_PREFIX, DEFAULT_CACHE_PREFIX)

    return cache_prefix

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
