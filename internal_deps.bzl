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

    # Pick a Stardoc compatible version.
    http_archive(
        name = "rules_license",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_license/releases/download/1.0.0/rules_license-1.0.0.tar.gz",
            "https://github.com/bazelbuild/rules_license/releases/download/1.0.0/rules_license-1.0.0.tar.gz",
        ],
        sha256 = "26d4021f6898e23b82ef953078389dd49ac2b5618ac564ade4ef87cced147b38",
    )

    http_archive(
        name = "rules_java",
        urls = [
            "https://github.com/bazelbuild/rules_java/releases/download/8.11.0/rules_java-8.11.0.tar.gz",
        ],
        sha256 = "d31b6c69e479ffa45460b64dc9c7792a431cac721ef8d5219fc9f603fa2ff877",
    )

    http_archive(
        name = "io_bazel_rules_go",
        sha256 = "130739704540caa14e77c54810b9f01d6d9ae897d53eedceb40fd6b75efc3c23",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.54.1/rules_go-v0.54.1.zip"],
    )

    http_archive(
        name = "io_buildbuddy_buildbuddy_toolchain",
        sha256 = "56d26379f80fd95ab94ba0e2198733b2ea4d928b326e6481196c1c2d4018cfc7",
        strip_prefix = "buildbuddy-toolchain-66146a3015faa348391fcceea2120caa390abe03",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/66146a3015faa348391fcceea2120caa390abe03.tar.gz"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "9f9f3b300a9264e4c77999312ce663be5dee9a56e361a1f6fe7ec60e1beef9a3",
        strip_prefix = "rules_python-1.4.1",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.4.1/rules_python-1.4.1.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "7c40b746387cd0c9a4d5bb0b2035abd134b3f7511015710a5ee5e07591008dde",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.43.0/bazel-gazelle-v0.43.0.tar.gz"],
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "8f56ebe33c788ce7a945a74bc2f62de33efdd9d35f07468a109f1d599784dd26",
        strip_prefix = "rules_multirun-0.12.0",
        url = "https://github.com/keith/rules_multirun/archive/refs/tags/0.12.0.tar.gz",
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "bf9101bd5d657046674167986a18d44c5612e417194dc55aff8ca174344de031",
        strip_prefix = "buildifier-prebuilt-8.0.3",
        urls = [
            "http://github.com/keith/buildifier-prebuilt/archive/8.0.3.tar.gz",
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
        name = "stardoc",
        sha256 = "ca933f39f2a6e0ad392fa91fd662545afcbd36c05c62365538385d35a0323096",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.8.0/stardoc-0.8.0.tar.gz"],
    )

    http_archive(
        name = "rules_bazel_integration_test",
        sha256 = "2f736646a6e38261eb278f44cb1e6a4c2d4cd1d8b7d16d4d26d0a891b430e8d5",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.32.1/rules_bazel_integration_test.v0.32.1.tar.gz",
        ],
    )

    # Implicit dependency of rules_bazel_integration_test, see
    # https://github.com/bazel-contrib/rules_bazel_integration_test/issues/381
    http_archive(
        name = "rules_shell",
        sha256 = "bc61ef94facc78e20a645726f64756e5e285a045037c7a61f65af2941f4c25e1",
        strip_prefix = "rules_shell-0.4.1",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.4.1/rules_shell-v0.4.1.tar.gz",
    )
