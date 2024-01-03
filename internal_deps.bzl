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
        sha256 = "7c76d6236b28ff695aa28cf35f95de317a9472fd1fb14ac797c9bf684f09b37c",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.44.2/rules_go-v0.44.2.zip"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "e85ae30de33625a63eca7fc40a94fea845e641888e52f32b6beea91e8b1b2793",
        strip_prefix = "rules_python-0.27.1",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.27.1/rules_python-0.27.1.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "32938bda16e6700063035479063d9d24c60eda8d79fd4739563f50d331cb3209",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.35.0/bazel-gazelle-v0.35.0.tar.gz"],
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "9cd384e42b2da00104f0e18f25e66285aa21f64b573c667638a7a213206885ab",
        strip_prefix = "rules_multirun-0.6.1",
        url = "https://github.com/keith/rules_multirun/archive/refs/tags/0.6.1.tar.gz",
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
        sha256 = "62bd2e60216b7a6fec3ac79341aa201e0956477e7c8f6ccc286f279ad1d96432",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.6.2/stardoc-0.6.2.tar.gz"],
    )

    http_archive(
        name = "rules_bazel_integration_test",
        sha256 = "6e65d497c68f5794349bfa004369e144063686ce1ebd0227717cd23285be45ef",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.20.0/rules_bazel_integration_test.v0.20.0.tar.gz",
        ],
    )
