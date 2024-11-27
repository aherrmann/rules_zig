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
        sha256 = "1eea4ef7179e6030326f16625e650593a5b96c094d9ccddcd9ef1cc24bad1297",
        strip_prefix = "buildbuddy-toolchain-eb143d1cf81dcc3ddbf0be5b9950cf8c14aa2de9",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/eb143d1cf81dcc3ddbf0be5b9950cf8c14aa2de9.tar.gz"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "ca2671529884e3ecb5b79d6a5608c7373a82078c3553b1fa53206e6b9dddab34",
        strip_prefix = "rules_python-0.38.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.38.0/rules_python-0.38.0.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "a80893292ae1d78eaeedd50d1cab98f242a17e3d5741b1b9fb58b5fd9d2d57bc",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.40.0/bazel-gazelle-v0.40.0.tar.gz"],
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
        sha256 = "04d7816612a7aa25b1d9cd40e4bbad7e7da7a7731cf4a9bece69e9711ea26d4b",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.27.0/rules_bazel_integration_test.v0.27.0.tar.gz",
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
