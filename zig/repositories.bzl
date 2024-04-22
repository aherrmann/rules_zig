"""Declare rules_zig dependencies and toolchains.

These are needed for local development, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", __http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//zig/private:platforms.bzl", "PLATFORMS")
load("//zig/private:versions.bzl", "TOOL_VERSIONS")
load("//zig/private/repo:toolchains_repo.bzl", "sanitize_version", "toolchains_repo")
load("//zig/private/repo:zig_repository.bzl", _zig_repository = "zig_repository")

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
        sha256 = "b554eb7942a5ab44c90077df6a0c76fc67c5874c9446a007e9ba68be82bd4796",
        strip_prefix = "bazel-lib-2.7.1",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.7.1/bazel-lib-v2.7.1.tar.gz",
    )

########
# Remaining content of the file is only used to support toolchains.
########

def zig_repository(*, name, zig_version, platform, **kwargs):
    """Fetch and install a Zig toolchain.

    Args:
      name: string, A unique name for the repository.
      zig_version: string, The Zig SDK version number.
      platform: string, The platform that the Zig SDK can execute on, e.g. `x86_64-linux` or `aarch64-macos`.
      **kwargs: Passed to the underlying repository rule.
    """
    _zig_repository(
        name = name,
        url = TOOL_VERSIONS[zig_version][platform].url,
        integrity = TOOL_VERSIONS[zig_version][platform].integrity,
        zig_version = zig_version,
        platform = platform,
        **kwargs
    )

def zig_repositories(**kwargs):
    """Fetch and install a Zig toolchain.

    Args:
      **kwargs: forwarded to `zig_repository`.

    Deprecated:
      Use `zig_repository` instead.
    """
    zig_repository(**kwargs)

# Wrapper macro around everything above, this is the primary API
def zig_register_toolchains(*, name, zig_versions = None, zig_version = None, register = True, **kwargs):
    """Convenience macro for users which does typical setup.

    - create a repository for each version and built-in platform like
      "zig_0.10.1_linux_amd64" - this repository is lazily fetched when zig is
      needed for that version and platform.
    - TODO: create a convenience repository for the host platform like "zig_host"
    - create a repository exposing toolchains for each platform like "zig_platforms"
    - register a toolchain pointing at each platform

    Users can avoid this macro and do these steps themselves, if they want more control.

    Args:
        name: base name for all created repos, like "zig".
        zig_versions: The list of Zig SDK versions to fetch,
            toolchains are registered in the given order.
        zig_version: A single Zig SDK version to fetch.
            Do not use together with zig_versions.
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users,
            but False when used under bzlmod extension.
        **kwargs: passed to each zig_repository call
    """
    versions_unset = zig_versions == None
    version_unset = zig_version == None
    both_unset = versions_unset and version_unset
    both_set = not versions_unset and not version_unset
    if both_unset or both_set:
        fail("You must specify one of `zig_versions` or `zig_version`")

    if versions_unset:
        zig_versions = [zig_version]

    for zig_version in zig_versions:
        sanitized_zig_version = sanitize_version(zig_version)
        for platform in PLATFORMS.keys():
            zig_repository(
                name = name + "_" + sanitized_zig_version + "_" + platform,
                zig_version = zig_version,
                platform = platform,
                **kwargs
            )

    toolchains_repo(
        name = name + "_toolchains",
        user_repository_name = name,
        zig_versions = zig_versions,
    )

    if register:
        native.register_toolchains("@%s_toolchains//:all" % name)
        native.register_toolchains("@rules_zig//zig/target:all")
