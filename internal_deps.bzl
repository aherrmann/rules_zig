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
        name = "io_bazel_rules_go",
        sha256 = "33acc4ae0f70502db4b893c9fc1dd7a9bf998c23e7ff2c4517741d4049a976f8",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.48.0/rules_go-v0.48.0.zip"],
    )

    http_archive(
        name = "io_buildbuddy_buildbuddy_toolchain",
        sha256 = "6d74221174f1759652ae4f204e009b5c234b781d13252a43933a2141fbf117b9",
        strip_prefix = "buildbuddy-toolchain-dfb7aadff5783bee5f53682144486265ed5e8941",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/dfb7aadff5783bee5f53682144486265ed5e8941.tar.gz"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "4912ced70dc1a2a8e4b86cec233b192ca053e82bc72d877b98e126156e8f228d",
        strip_prefix = "rules_python-0.32.2",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.32.2/rules_python-0.32.2.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "d76bf7a60fd8b050444090dfa2837a4eaf9829e1165618ee35dceca5cbdf58d5",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.37.0/bazel-gazelle-v0.37.0.tar.gz"],
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "504612040149edce01376c4809b33f2e0c5331cdd0ec56df562dc89ecbc045a0",
        strip_prefix = "rules_multirun-0.9.0",
        url = "https://github.com/keith/rules_multirun/archive/refs/tags/0.9.0.tar.gz",
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "8ada9d88e51ebf5a1fdff37d75ed41d51f5e677cdbeafb0a22dda54747d6e07e",
        strip_prefix = "buildifier-prebuilt-6.4.0",
        urls = [
            "http://github.com/keith/buildifier-prebuilt/archive/6.4.0.tar.gz",
        ],
    )

    # Override bazel_skylib distribution to fetch sources instead
    # so that the gazelle extension is included
    # see https://github.com/bazelbuild/bazel-skylib/issues/250
    http_archive(
        name = "bazel_skylib",
        sha256 = "9f38886a40548c6e96c106b752f242130ee11aaa068a56ba7e56f4511f33e4f2",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.6.1/bazel-skylib-1.6.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.6.1/bazel-skylib-1.6.1.tar.gz",
        ],
    )

    http_archive(
        name = "bazel_skylib_gazelle_plugin",
        sha256 = "2e4a533f7a303076a5d43191b3696c071b9bc0020eb00ec07c3e02bd9ce3093d",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.0/bazel-skylib-gazelle-plugin-1.7.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.0/bazel-skylib-gazelle-plugin-1.7.0.tar.gz",
        ],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "62bd2e60216b7a6fec3ac79341aa201e0956477e7c8f6ccc286f279ad1d96432",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.6.2/stardoc-0.6.2.tar.gz"],
    )

    http_archive(
        name = "rules_bazel_integration_test",
        sha256 = "fe43a0ef76323813c912b7256a5f01f87f2697528b107627b70da58c50b1988a",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.23.0/rules_bazel_integration_test.v0.23.0.tar.gz",
        ],
    )
