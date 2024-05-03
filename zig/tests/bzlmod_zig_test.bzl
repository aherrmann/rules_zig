"""Unit tests for Zig module extension."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//zig/private/bzlmod:zig.bzl",
    "handle_toolchain_tags",
    "parse_zig_versions_json",
)

def _parse_zig_index_test_impl(ctx):
    env = unittest.begin(ctx)

    content = "{}"
    expected = {}
    result = parse_zig_versions_json(content)
    asserts.equals(env, (None, expected), result)

    content = """\
{
  "0.12.0": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-linux-aarch64-0.12.0.tar.xz",
      "shasum": "754f1029484079b7e0ca3b913a0a2f2a6afd5a28990cb224fe8845e72f09de63"
    }
  }
}
"""
    expected = {
        "0.12.0": {
            "aarch64-linux": struct(
                url = "https://ziglang.org/download/0.12.0/zig-linux-aarch64-0.12.0.tar.xz",
                sha256 = "754f1029484079b7e0ca3b913a0a2f2a6afd5a28990cb224fe8845e72f09de63",
            ),
        },
    }
    result = parse_zig_versions_json(content)
    asserts.equals(env, (None, expected), result)

    content = """\
{
  "0.12.0": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-linux-aarch64-0.12.0.tar.xz",
      "shasum": "754f1029484079b7e0ca3b913a0a2f2a6afd5a28990cb224fe8845e72f09de63"
    }
  },
  "0.11.0": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-linux-aarch64-0.11.0.tar.xz",
      "shasum": "956eb095d8ba44ac6ebd27f7c9956e47d92937c103bf754745d0a39cdaa5d4c6"
    },
    "aarch64-macos": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-macos-aarch64-0.11.0.tar.xz",
      "shasum": "c6ebf927bb13a707d74267474a9f553274e64906fd21bf1c75a20bde8cadf7b2"
    }
  }
}
"""
    expected = {
        "0.12.0": {
            "aarch64-linux": struct(
                url = "https://ziglang.org/download/0.12.0/zig-linux-aarch64-0.12.0.tar.xz",
                sha256 = "754f1029484079b7e0ca3b913a0a2f2a6afd5a28990cb224fe8845e72f09de63",
            ),
        },
        "0.11.0": {
            "aarch64-linux": struct(
                url = "https://ziglang.org/download/0.11.0/zig-linux-aarch64-0.11.0.tar.xz",
                sha256 = "956eb095d8ba44ac6ebd27f7c9956e47d92937c103bf754745d0a39cdaa5d4c6",
            ),
            "aarch64-macos": struct(
                url = "https://ziglang.org/download/0.11.0/zig-macos-aarch64-0.11.0.tar.xz",
                sha256 = "c6ebf927bb13a707d74267474a9f553274e64906fd21bf1c75a20bde8cadf7b2",
            ),
        },
    }
    result = parse_zig_versions_json(content)
    asserts.equals(env, (None, expected), result)

    content = ""
    expected_err = "Invalid JSON format in Zig SDK version index."
    result = parse_zig_versions_json(content)
    asserts.equals(env, (expected_err, None), result)

    content = """\
{
  "0.12.0": {
    "aarch64-linux": {
      "shasum": "754f1029484079b7e0ca3b913a0a2f2a6afd5a28990cb224fe8845e72f09de63"
    }
  }
}
"""
    expected_err = "Missing `tarball` field in Zig SDK version index."
    result = parse_zig_versions_json(content)
    asserts.equals(env, (expected_err, None), result)

    content = """\
{
  "0.12.0": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-linux-aarch64-0.12.0.tar.xz"
    }
  }
}
"""
    expected_err = "Missing `shasum` field in Zig SDK version index."
    result = parse_zig_versions_json(content)
    asserts.equals(env, (expected_err, None), result)

    return unittest.end(env)

_parse_zig_index_test = unittest.make(
    _parse_zig_index_test_impl,
)

def _zig_versions_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (None, ["0.1.0"]),
        handle_toolchain_tags([], known_versions = ["0.1.0"]),
        "should fall back to the default Zig SDK version",
    )

    asserts.equals(
        env,
        (None, ["0.1.0"]),
        handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.1.0",
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        ),
        "should choose a single configured version",
    )

    asserts.equals(
        env,
        (None, ["0.4.0", "0.2.0", "0.1.0", "0.0.1"]),
        handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.0.1",
                            ),
                            struct(
                                default = False,
                                zig_version = "0.4.0",
                            ),
                        ],
                    ),
                ),
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.2.0",
                            ),
                            struct(
                                default = False,
                                zig_version = "0.1.0",
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.4.0", "0.2.0", "0.1.0", "0.0.1"],
        ),
        "should order versions by semver",
    )

    asserts.equals(
        env,
        (None, ["0.1.0", "0.0.1"]),
        handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.0.1",
                            ),
                            struct(
                                default = False,
                                zig_version = "0.1.0",
                            ),
                        ],
                    ),
                ),
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.0.1",
                            ),
                            struct(
                                default = False,
                                zig_version = "0.1.0",
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0", "0.0.1"],
        ),
        "should deduplicate versions",
    )

    asserts.equals(
        env,
        (None, ["0.1.0", "0.4.0", "0.2.0", "0.0.1"]),
        handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.0.1",
                            ),
                            struct(
                                default = False,
                                zig_version = "0.4.0",
                            ),
                        ],
                    ),
                ),
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.2.0",
                            ),
                            struct(
                                default = True,
                                zig_version = "0.1.0",
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.4.0", "0.2.0", "0.1.0", "0.0.1"],
        ),
        "the default should take precedence",
    )

    asserts.equals(
        env,
        (None, ["0.1.0", "0.2.0", "0.0.1"]),
        handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.0.1",
                            ),
                            struct(
                                default = False,
                                zig_version = "0.1.0",
                            ),
                        ],
                    ),
                ),
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = False,
                                zig_version = "0.2.0",
                            ),
                            struct(
                                default = True,
                                zig_version = "0.1.0",
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.2.0", "0.1.0", "0.0.1"],
        ),
        "should not duplicate default",
    )

    asserts.equals(
        env,
        (["Only the root module may specify a default Zig SDK version.", struct(
            default = True,
            zig_version = "0.1.0",
        )], None),
        handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = True,
                                zig_version = "0.1.0",
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        ),
        "only root may set default",
    )

    asserts.equals(
        env,
        (["You may only specify one default Zig SDK version.", struct(
            default = True,
            zig_version = "0.2.0",
        )], None),
        handle_toolchain_tags(
            [
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [
                            struct(
                                default = True,
                                zig_version = "0.1.0",
                            ),
                            struct(
                                default = True,
                                zig_version = "0.2.0",
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.2.0", "0.1.0"],
        ),
        "only one default allowed",
    )

    return unittest.end(env)

_zig_versions_test = unittest.make(
    _zig_versions_test_impl,
)

def bzlmod_zig_test_suite(name):
    unittest.suite(
        name,
        partial.make(_zig_versions_test, size = "small"),
        partial.make(_parse_zig_index_test, size = "small"),
    )
