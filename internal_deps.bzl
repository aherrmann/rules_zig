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
        sha256 = "f4a9314518ca6acfa16cc4ab43b0b8ce1e4ea64b81c38d8a3772883f153346b8",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.50.1/rules_go-v0.50.1.zip"],
    )

    http_archive(
        name = "io_buildbuddy_buildbuddy_toolchain",
        sha256 = "747dbf28cb8b8d27b2d909aa05e00691fe6d9d8a28026e359cc4943261687592",
        strip_prefix = "buildbuddy-toolchain-702567fd8a561ec94a0e8e7fd8aa00bb15d87b4f",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/702567fd8a561ec94a0e8e7fd8aa00bb15d87b4f.tar.gz"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "ca77768989a7f311186a29747e3e95c936a41dffac779aff6b443db22290d913",
        strip_prefix = "rules_python-0.36.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.36.0/rules_python-0.36.0.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "b760f7fe75173886007f7c2e616a21241208f3d90e8657dc65d36a771e916b6a",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.39.1/bazel-gazelle-v0.39.1.tar.gz"],
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "504612040149edce01376c4809b33f2e0c5331cdd0ec56df562dc89ecbc045a0",
        strip_prefix = "rules_multirun-0.9.0",
        url = "https://github.com/keith/rules_multirun/archive/refs/tags/0.9.0.tar.gz",
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
        sha256 = "b079b84278435441023f03de1a72baff9e4e4fe2cb1092ed4c9b60dc8b42e732",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.25.0/rules_bazel_integration_test.v0.25.0.tar.gz",
        ],
    )
