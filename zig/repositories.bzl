"""Declare rules_zig dependencies and toolchains.

These are needed for local development, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", __http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//zig/private:toolchains_repo.bzl", "PLATFORMS", "toolchains_repo")
load("//zig/private:versions.bzl", "TOOL_VERSIONS")

def _http_archive(name, **kwargs):
    maybe(__http_archive, name = name, **kwargs)

# WARNING: any changes in this function may be BREAKING CHANGES for users
# because we'll fetch a dependency which may be different from one that
# they were previously fetching later in their WORKSPACE setup, and now
# ours took precedence. Such breakages are challenging for users, so any
# changes in this function should be marked as BREAKING in the commit message
# and released only in semver majors.
# This is all fixed by bzlmod, so we just tolerate it for now.
def rules_zig_dependencies():
    """Register dependencies required by rules_zig."""

    _http_archive(
        name = "bazel_skylib",
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.3.0.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
        ],
    )

    _http_archive(
        name = "aspect_bazel_lib",
        sha256 = "979667bb7276ee8fcf2c114c9be9932b9a3052a64a647e0dcaacfb9c0016f0a3",
        strip_prefix = "bazel-lib-2.4.1",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.4.1/bazel-lib-v2.4.1.tar.gz",
    )

########
# Remaining content of the file is only used to support toolchains.
########
_DOC = "Fetch and install a Zig toolchain."
_ATTRS = {
    "zig_version": attr.string(mandatory = True, values = TOOL_VERSIONS.keys()),
    "platform": attr.string(mandatory = True, values = PLATFORMS.keys()),
}

def _zig_repo_impl(repository_ctx):
    url = TOOL_VERSIONS[repository_ctx.attr.zig_version][repository_ctx.attr.platform].url
    integrity = TOOL_VERSIONS[repository_ctx.attr.zig_version][repository_ctx.attr.platform].integrity
    basename = url.rsplit("/", 1)[1]
    if basename.endswith(".tar.gz") or basename.endswith(".tar.xz"):
        prefix = basename[:-7]
    elif basename.endswith(".zip"):
        prefix = basename[:-4]
    else:
        fail("Cannot download Zig SDK at {}. Unsupported file extension.".format(url))
    repository_ctx.download_and_extract(
        url = url,
        integrity = integrity,
        stripPrefix = prefix,
    )

    build_content = """#Generated by zig/repositories.bzl
load("@rules_zig//zig:toolchain.bzl", "zig_toolchain")
zig_toolchain(
    name = "zig_toolchain",
    zig_exe = select({{
        "@bazel_tools//src/conditions:host_windows": "zig.exe",
        "//conditions:default": "zig",
    }}),
    zig_lib = glob(["lib/**"]),
    zig_lib_path = "lib",
    zig_version = "{zig_version}",
)
""".format(
        zig_version = repository_ctx.attr.zig_version,
    )

    # Base BUILD file for this repository
    repository_ctx.file("BUILD.bazel", build_content)

zig_repositories = repository_rule(
    _zig_repo_impl,
    doc = _DOC,
    attrs = _ATTRS,
)

# Wrapper macro around everything above, this is the primary API
def zig_register_toolchains(*, name, register = True, **kwargs):
    """Convenience macro for users which does typical setup.

    - create a repository for each built-in platform like "zig_linux_amd64" -
      this repository is lazily fetched when zig is needed for that platform.
    - TODO: create a convenience repository for the host platform like "zig_host"
    - create a repository exposing toolchains for each platform like "zig_platforms"
    - register a toolchain pointing at each platform

    Users can avoid this macro and do these steps themselves, if they want more control.

    Args:
        name: base name for all created repos, like "zig1_14"
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users,
            but False when used under bzlmod extension.
        **kwargs: passed to each zig_repositories call
    """
    for platform in PLATFORMS.keys():
        zig_repositories(
            name = name + "_" + platform,
            platform = platform,
            **kwargs
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    toolchains_repo(
        name = name + "_toolchains",
        user_repository_name = name,
    )

    if register:
        native.register_toolchains("@rules_zig//zig/target:all")
