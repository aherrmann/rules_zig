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
        sha256 = "1a6706f05fa053c74734591d417641b99074e83101c618e995efe563e7f3d377",
        strip_prefix = "buildbuddy-toolchain-9719443cbc4c313e6de4c9bd419f232c139eea43",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/9719443cbc4c313e6de4c9bd419f232c139eea43.tar.gz"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "c6fb25d0ba0246f6d5bd820dd0b2e66b339ccc510242fd4956b9a639b548d113",
        strip_prefix = "rules_python-0.37.2",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.37.2/rules_python-0.37.2.tar.gz",
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
        sha256 = "ab56cdd55a28781287242c7124ce9ff791ae8318ed641057f10edd98c55d7ed5",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.26.0/rules_bazel_integration_test.v0.26.0.tar.gz",
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
