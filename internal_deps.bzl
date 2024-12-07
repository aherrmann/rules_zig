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
        sha256 = "500fa9a1869615b3f182da00dab7b8997f3d737ffcc98721a4ac2be29bef18ec",
        strip_prefix = "buildbuddy-toolchain-ffd296b7a9821174cdb2188d1373fd262cacb09d",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/ffd296b7a9821174cdb2188d1373fd262cacb09d.tar.gz"],
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
        sha256 = "44ed2cacf9dfdbfd0e2ef60022ca5ada9b11f337ecaec3c428d5003b38043589",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.28.0/rules_bazel_integration_test.v0.28.0.tar.gz",
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
