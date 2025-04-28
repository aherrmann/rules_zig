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
        sha256 = "f2d15bea3e241aa0e3a90fb17a82e6a8ab12214789f6aeddd53b8d04316d2b7c",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.54.0/rules_go-v0.54.0.zip"],
    )

    http_archive(
        name = "io_buildbuddy_buildbuddy_toolchain",
        sha256 = "56d26379f80fd95ab94ba0e2198733b2ea4d928b326e6481196c1c2d4018cfc7",
        strip_prefix = "buildbuddy-toolchain-66146a3015faa348391fcceea2120caa390abe03",
        urls = ["https://github.com/buildbuddy-io/buildbuddy-toolchain/archive/66146a3015faa348391fcceea2120caa390abe03.tar.gz"],
    )

    http_archive(
        name = "rules_python",
        sha256 = "2cc26bbd53854ceb76dd42a834b1002cd4ba7f8df35440cf03482e045affc244",
        strip_prefix = "rules_python-1.3.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.3.0/rules_python-1.3.0.tar.gz",
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "7c40b746387cd0c9a4d5bb0b2035abd134b3f7511015710a5ee5e07591008dde",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.43.0/bazel-gazelle-v0.43.0.tar.gz"],
    )

    http_archive(
        name = "rules_multirun",
        sha256 = "d4c613d27dae7769bf1f51338c52ca4392d0ad5e3473cf6d0daeeb90a0e410fb",
        strip_prefix = "rules_multirun-0.11.0",
        url = "https://github.com/keith/rules_multirun/archive/refs/tags/0.11.0.tar.gz",
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
        name = "io_bazel_stardoc",
        sha256 = "ca933f39f2a6e0ad392fa91fd662545afcbd36c05c62365538385d35a0323096",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.8.0/stardoc-0.8.0.tar.gz"],
    )

    http_archive(
        name = "rules_bazel_integration_test",
        sha256 = "3c9b9abea07acee98ee4a2ab7447784b1d6e39dff88c3eaf97ca227138349b15",
        urls = [
            "https://github.com/bazel-contrib/rules_bazel_integration_test/releases/download/v0.32.0/rules_bazel_integration_test.v0.32.0.tar.gz",
        ],
    )

    # Implicit dependency of rules_bazel_integration_test, see
    # https://github.com/bazel-contrib/rules_bazel_integration_test/issues/381
    http_archive(
        name = "rules_shell",
        sha256 = "3e114424a5c7e4fd43e0133cc6ecdfe54e45ae8affa14fadd839f29901424043",
        strip_prefix = "rules_shell-0.4.0",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.4.0/rules_shell-v0.4.0.tar.gz",
    )
