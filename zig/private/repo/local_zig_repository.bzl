"""Implementation of a repository rule for a host-local Zig toolchain."""

load(
    "//zig/private/common:zig_cache.bzl",
    "VAR_CACHE_PREFIX",
    "VAR_CACHE_PREFIX_LINUX",
    "VAR_CACHE_PREFIX_MACOS",
    "VAR_CACHE_PREFIX_WINDOWS",
    "env_zig_cache_prefix",
)
load("//zig/private/repo:toolchain_build_file.bzl", "render_toolchain_build")

DOC = "Expose a host-local Zig toolchain via a synthetic repository."

ATTRS = {
    "zig_exe_path": attr.string(mandatory = True, doc = "Absolute path to the Zig executable."),
    "zig_lib_path": attr.string(mandatory = True, doc = "Absolute path to the Zig lib directory."),
    "zig_version": attr.string(mandatory = True, doc = "The Zig SDK version number."),
    "platform": attr.string(mandatory = True, doc = "The execution platform for this Zig SDK, e.g. `x86_64-linux`."),
    "translate_c": attr.label(doc = "The translate-c label.", mandatory = False),
}

ENV = [
    VAR_CACHE_PREFIX,
    VAR_CACHE_PREFIX_LINUX,
    VAR_CACHE_PREFIX_MACOS,
    VAR_CACHE_PREFIX_WINDOWS,
]

def _zig_exe_name(*, platform):
    return "zig.exe" if platform.find("windows") != -1 else "zig"

def _local_zig_repository_impl(repository_ctx):
    cache_prefix = env_zig_cache_prefix(
        repository_ctx.os.environ,
        repository_ctx.attr.platform,
    )

    zig_exe = _zig_exe_name(platform = repository_ctx.attr.platform)
    repository_ctx.symlink(repository_ctx.path(repository_ctx.attr.zig_exe_path), zig_exe)
    repository_ctx.symlink(repository_ctx.path(repository_ctx.attr.zig_lib_path), "lib")
    repository_ctx.file(
        "BUILD.bazel",
        render_toolchain_build(
            zig_cache = cache_prefix,
            zig_exe = zig_exe,
            zig_version = repository_ctx.attr.zig_version,
            translate_c = repository_ctx.attr.translate_c,
        ),
    )

local_zig_repository = repository_rule(
    implementation = _local_zig_repository_impl,
    attrs = ATTRS,
    doc = DOC,
    environ = ENV,
)
