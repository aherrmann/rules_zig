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
        sha256 = "19ef30b21eae581177e0028f6f4b1f54c66467017be33d211ab6fc81da01ea4d",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.38.0/rules_go-v0.38.0.zip"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "9acc0944c94adb23fba1c9988b48768b1bacc6583b52a2586895c5b7491e2e31",
        strip_prefix = "rules_python-0.27.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.27.0/rules_python-0.27.0.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "b7387f72efb59f876e4daae42f1d3912d0d45563eac7cb23d1de0b094ab588cf",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.34.0/bazel-gazelle-v0.34.0.tar.gz"],
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "9cd384e42b2da00104f0e18f25e66285aa21f64b573c667638a7a213206885ab",
        strip_prefix = "rules_multirun-0.6.1",
        url = "https://github.com/keith/rules_multirun/archive/refs/tags/0.6.1.tar.gz",
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "72b5bb0853aac597cce6482ee6c62513318e7f2c0050bc7c319d75d03d8a3875",
        strip_prefix = "buildifier-prebuilt-6.3.3",
        urls = [
            "http://github.com/keith/buildifier-prebuilt/archive/6.3.3.tar.gz",
        ],
    )

    # Override bazel_skylib distribution to fetch sources instead
    # so that the gazelle extension is included
    # see https://github.com/bazelbuild/bazel-skylib/issues/250
    http_archive(
        name = "bazel_skylib",
        sha256 = "cd55a062e763b9349921f0f5db8c3933288dc8ba4f76dd9416aac68acee3cb94",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
        ],
    )

    http_archive(
        name = "bazel_skylib_gazelle_plugin",
        sha256 = "747addf3f508186234f6232674dd7786743efb8c68619aece5fb0cac97b8f415",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-gazelle-plugin-1.5.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-gazelle-plugin-1.5.0.tar.gz",
        ],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "3fd8fec4ddec3c670bd810904e2e33170bedfe12f90adf943508184be458c8bb",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.5.3/stardoc-0.5.3.tar.gz"],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "4d6010ca5e3bb4d7045b071205afa8db06ec11eb24de3f023d74d77cca765f66",
        strip_prefix = "bazel-lib-1.39.0",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v1.39.0/bazel-lib-v1.39.0.tar.gz",
    )

    http_archive(
        name = "rules_bazel_integration_test",
        sha256 = "567ef30550a90c0dc22a9076743b2b2715b4d7148b4d573bdcc61aaa5d0177b3",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.18.0/rules_bazel_integration_test.v0.18.0.tar.gz",
        ],
    )
