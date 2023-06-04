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
        name = "bazel_gazelle",
        sha256 = "727f3e4edd96ea20c29e8c2ca9e8d2af724d8c7778e7923a854b2c80952bc405",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.30.0/bazel-gazelle-v0.30.0.tar.gz"],
    )

    http_file(
        name = "com_github_bazelbuild_buildtools_buildozer_darwin_amd64",
        downloaded_file_path = "buildozer",
        executable = True,
        sha256 = "f9eb333006a2ad3b058670976ff9312cb7c1021593d76eceb31d38854be3ef8d",
        url = "https://github.com/bazelbuild/buildtools/releases/download/6.0.1/buildozer-darwin-amd64",
    )

    http_file(
        name = "com_github_bazelbuild_buildtools_buildozer_linux_amd64",
        downloaded_file_path = "buildozer",
        executable = True,
        sha256 = "a7ca6257f78088a795e7b6e37b78b7b76fb91de1d465d851078d0226f08b90c9",
        url = "https://github.com/bazelbuild/buildtools/releases/download/6.0.1/buildozer-linux-amd64",
    )

    http_file(
        name = "com_github_bazelbuild_buildtools_buildozer_windows_amd64",
        downloaded_file_path = "buildozer.exe",
        executable = True,
        sha256 = "371f7bde60db3f2d7f414fdd2dcd4de28cae6c2c65a0c88a5a82b143af642fbe",
        url = "https://github.com/bazelbuild/buildtools/releases/download/6.0.1/buildozer-windows-amd64.exe",
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "00aad85eca054dbb5dc12178a3c83fd4bbee83d4824d9d76bfd86ab757a4c327",
        strip_prefix = "rules_multirun-73017d503a524a9de59a5339c1db9cc4860cec2a",
        url = "https://github.com/keith/rules_multirun/archive/73017d503a524a9de59a5339c1db9cc4860cec2a.tar.gz",
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "e46c16180bc49487bfd0f1ffa7345364718c57334fa0b5b67cb5f27eba10f309",
        strip_prefix = "buildifier-prebuilt-6.1.0",
        urls = [
            "http://github.com/keith/buildifier-prebuilt/archive/6.1.0.tar.gz",
        ],
    )

    # Override bazel_skylib distribution to fetch sources instead
    # so that the gazelle extension is included
    # see https://github.com/bazelbuild/bazel-skylib/issues/250
    http_archive(
        name = "bazel_skylib",
        sha256 = "3b620033ca48fcd6f5ef2ac85e0f6ec5639605fa2f627968490e52fc91a9932f",
        strip_prefix = "bazel-skylib-1.3.0",
        urls = ["https://github.com/bazelbuild/bazel-skylib/archive/refs/tags/1.3.0.tar.gz"],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "3fd8fec4ddec3c670bd810904e2e33170bedfe12f90adf943508184be458c8bb",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.5.3/stardoc-0.5.3.tar.gz"],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "0aed9a6e7612b2968b5aa1ac0f801f5ec956ec2c04810da2c1445cac34938596",
        strip_prefix = "bazel-lib-1.29.0",
        url = "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v1.29.0.tar.gz",
    )

    http_archive(
        name = "contrib_rules_bazel_integration_test",
        sha256 = "6da8278ae7c78df6c7c222102c05e5807a3e5e65297f2a75968c899f7937750a",
        url = "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.10.3/rules_bazel_integration_test.v0.10.3.tar.gz",
    )
