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
        sha256 = "d93ef02f1e72c82d8bb3d5169519b36167b33cf68c252525e3b9d3d5dd143de7",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.49.0/rules_go-v0.49.0.zip"],
    )

    http_archive(
        name = "io_buildbuddy_buildbuddy_toolchain",
        sha256 = "baa9af1b9fcc96d18ac90a4dd68ebd2046c8beb76ed89aea9aabca30959ad30c",
        strip_prefix = "buildbuddy-toolchain-287d6042ad151be92de03c83ef48747ba832c4e2",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/287d6042ad151be92de03c83ef48747ba832c4e2.tar.gz"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "be04b635c7be4604be1ef20542e9870af3c49778ce841ee2d92fcb42f9d9516a",
        strip_prefix = "rules_python-0.35.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.35.0/rules_python-0.35.0.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "8ad77552825b078a10ad960bec6ef77d2ff8ec70faef2fd038db713f410f5d87",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.38.0/bazel-gazelle-v0.38.0.tar.gz"],
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "504612040149edce01376c4809b33f2e0c5331cdd0ec56df562dc89ecbc045a0",
        strip_prefix = "rules_multirun-0.9.0",
        url = "https://github.com/keith/rules_multirun/archive/refs/tags/0.9.0.tar.gz",
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "481f220bee90024f4e63d3e516a5e708df9cd736170543ceab334064fa773f41",
        strip_prefix = "buildifier-prebuilt-7.1.2",
        urls = [
            "http://github.com/keith/buildifier-prebuilt/archive/7.1.2.tar.gz",
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
        sha256 = "dd7f32f4fe2537ce2452c51f816a5962d48888a5b07de2c195f3b3da86c545d3",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.7.0/stardoc-0.7.0.tar.gz"],
    )

    http_archive(
        name = "rules_bazel_integration_test",
        sha256 = "7aa9b5269879dd8074b875259b4bd1d7338fd2878c01ad9537e0478de31dc72c",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.24.1/rules_bazel_integration_test.v0.24.1.tar.gz",
        ],
    )
