"""Our "development" dependencies

Users should *not* need to install these. If users see a load()
statement from these, that's a bug in our distribution.
"""

load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    _http_archive = "http_archive",
    _http_file = "http_file",
)
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def http_archive(name, **kwargs):
    maybe(_http_archive, name = name, **kwargs)

def http_file(name, **kwargs):
    maybe(_http_file, name = name, **kwargs)

def rules_zig_internal_deps():
    "Fetch deps needed for local development"
    http_archive(
        name = "rules_java",
        urls = [
            "https://github.com/bazelbuild/rules_java/releases/download/8.9.0/rules_java-8.9.0.tar.gz",
        ],
        sha256 = "8daa0e4f800979c74387e4cd93f97e576ec6d52beab8ac94710d2931c57f8d8b",
    )

    http_archive(
        name = "io_bazel_rules_go",
        sha256 = "0936c9bc3c4321ee372cb8f66dd972d368cb940ed01a9ba9fd7debcf0093f09b",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.51.0/rules_go-v0.51.0.zip"],
    )

    http_archive(
        name = "io_buildbuddy_buildbuddy_toolchain",
        sha256 = "7ba81c80b1e6247bf108d35b0924383ab5fc15b1a7f13892ed7495a61335654f",
        strip_prefix = "buildbuddy-toolchain-badf8034b2952ec613970a27f24fb140be7eaf73",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/badf8034b2952ec613970a27f24fb140be7eaf73.tar.gz"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "4f7e2aa1eb9aa722d96498f5ef514f426c1f55161c3c9ae628c857a7128ceb07",
        strip_prefix = "rules_python-1.0.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.0.0/rules_python-1.0.0.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "5d80e62a70314f39cc764c1c3eaa800c5936c9f1ea91625006227ce4d20cd086",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.42.0/bazel-gazelle-v0.42.0.tar.gz"],
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "e397783c0483a323f5414a09a698a89581114da258f0d41c39434e83d1963084",
        strip_prefix = "rules_multirun-0.10.0",
        url = "https://github.com/keith/rules_multirun/archive/refs/tags/0.10.0.tar.gz",
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "7f85b688a4b558e2d9099340cfb510ba7179f829454fba842370bccffb67d6cc",
        strip_prefix = "buildifier-prebuilt-7.3.1",
        urls = [
            "http://github.com/keith/buildifier-prebuilt/archive/7.3.1.tar.gz",
        ],
    )

    # Override bazel_skylib distribution to fetch sources instead
    # so that the gazelle extension is included
    # see https://github.com/bazelbuild/bazel-skylib/issues/250
    http_archive(
        name = "bazel_skylib",
        sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
        ],
    )

    http_archive(
        name = "bazel_skylib_gazelle_plugin",
        sha256 = "e0629e3cbacca15e2c659833b24b86174d22b664ca0a67f377108ff6a207cc8c",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-gazelle-plugin-1.7.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-gazelle-plugin-1.7.1.tar.gz",
        ],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "fabb280f6c92a3b55eed89a918ca91e39fb733373c81e87a18ae9e33e75023ec",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.7.1/stardoc-0.7.1.tar.gz"],
    )

    http_archive(
        name = "rules_bazel_integration_test",
        sha256 = "3c9b9abea07acee98ee4a2ab7447784b1d6e39dff88c3eaf97ca227138349b15",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.32.0/rules_bazel_integration_test.v0.32.0.tar.gz",
        ],
    )

    # Implicit dependency of rules_bazel_integration_test, see
    # https://github.com/bazel-contrib/rules_bazel_integration_test/issues/381
    http_archive(
        name = "rules_shell",
        sha256 = "d8cd4a3a91fc1dc68d4c7d6b655f09def109f7186437e3f50a9b60ab436a0c53",
        strip_prefix = "rules_shell-0.3.0",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.3.0/rules_shell-v0.3.0.tar.gz",
    )
