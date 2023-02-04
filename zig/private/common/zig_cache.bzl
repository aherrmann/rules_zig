"""Defines utilities to handle the Zig compiler cache."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def zig_cache_output(*, actions, name, outputs, args):
    """Handle the Zig compiler cache.

    Declares directory outputs for the local and global Zig compiler cache.
    Appends both to the given outputs list, and arguments object.

    Args:
      actions: `ctx.actions`.
      name: String, A unique name to distinguish this cache from others.
      outputs: List; mutable, Append the declared outputs to this list.
      args: Args; mutable, Append the Zig cache flags to this object.
    """

    # TODO[AH] Persist or share at least the global cache somehow.
    local_cache = actions.declare_directory(paths.join(".zig-cache", "local", name))
    global_cache = actions.declare_directory(paths.join(".zig-cache", "global", name))

    outputs.append(local_cache)
    outputs.append(global_cache)

    args.add_all(["--cache-dir", local_cache.path])
    args.add_all(["--global-cache-dir", global_cache.path])
