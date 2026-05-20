"""Unit tests for Zig module extension."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//zig/private/bzlmod:zig.bzl",
    "handle_toolchain_tags",
    "merge_version_specs",
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

    content = """\
{
  "master": {
    "version": "0.13.0-dev.46+3648d7df1",
    "x86_64-macos": {
      "tarball": "https://ziglang.org/builds/zig-macos-x86_64-0.13.0-dev.46+3648d7df1.tar.xz",
      "shasum": "d8fb090bd69d7e191a3443520da5c52da430fbffc0de12ac87a114a6cc1f20ca",
      "size": "47206948"
    }
  }
}
"""
    expected = {
        "0.13.0-dev.46+3648d7df1": {
            "x86_64-macos": struct(
                url = "https://ziglang.org/builds/zig-macos-x86_64-0.13.0-dev.46+3648d7df1.tar.xz",
                sha256 = "d8fb090bd69d7e191a3443520da5c52da430fbffc0de12ac87a114a6cc1f20ca",
            ),
        },
    }
    result = parse_zig_versions_json(content)
    asserts.equals(env, (None, expected), result)

    content = """\
{
  "master": {
    "version": "0.13.0-dev.46+3648d7df1",
    "date": "2024-04-26",
    "docs": "https://ziglang.org/documentation/master/",
    "stdDocs": "https://ziglang.org/documentation/master/std/",
    "src": {
      "tarball": "https://ziglang.org/builds/zig-0.13.0-dev.46+3648d7df1.tar.xz",
      "shasum": "08190cb4482be355acaecaae9d7936e4fad47180c97ca8138b97a122a313cd99",
      "size": "17111524"
    },
    "bootstrap": {
      "tarball": "https://ziglang.org/builds/zig-bootstrap-0.13.0-dev.46+3648d7df1.tar.xz",
      "shasum": "78569b44dbfb8ec0cddbd1fa69ce398b973bd05c7f3b87f070cc2a0ba9c86571",
      "size": "45555796"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/builds/zig-macos-x86_64-0.13.0-dev.46+3648d7df1.tar.xz",
      "shasum": "d8fb090bd69d7e191a3443520da5c52da430fbffc0de12ac87a114a6cc1f20ca",
      "size": "47206948"
    }
  },
  "0.12.0": {
    "date": "2024-04-20",
    "docs": "https://ziglang.org/documentation/0.12.0/",
    "stdDocs": "https://ziglang.org/documentation/0.12.0/std/",
    "notes": "https://ziglang.org/download/0.12.0/release-notes.html",
    "src": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-0.12.0.tar.xz",
      "shasum": "a6744ef84b6716f976dad923075b2f54dc4f785f200ae6c8ea07997bd9d9bd9a",
      "size": "17099152"
    },
    "bootstrap": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-bootstrap-0.12.0.tar.xz",
      "shasum": "3efc643d56421fa68072af94d5512cb71c61acf1c32512f77c0b4590bff63187",
      "size": "45527312"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-macos-x86_64-0.12.0.tar.xz",
      "shasum": "4d411bf413e7667821324da248e8589278180dbc197f4f282b7dbb599a689311",
      "size": "47185720"
    }
  }
}
"""
    expected = {
        "0.13.0-dev.46+3648d7df1": {
            "x86_64-macos": struct(
                url = "https://ziglang.org/builds/zig-macos-x86_64-0.13.0-dev.46+3648d7df1.tar.xz",
                sha256 = "d8fb090bd69d7e191a3443520da5c52da430fbffc0de12ac87a114a6cc1f20ca",
            ),
        },
        "0.12.0": {
            "x86_64-macos": struct(
                url = "https://ziglang.org/download/0.12.0/zig-macos-x86_64-0.12.0.tar.xz",
                sha256 = "4d411bf413e7667821324da248e8589278180dbc197f4f282b7dbb599a689311",
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

    content = """\
{
  "bad-version": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-linux-aarch64-0.12.0.tar.xz",
      "shasum": "754f1029484079b7e0ca3b913a0a2f2a6afd5a28990cb224fe8845e72f09de63"
    }
  }
}
"""
    expected_err = "Malformed version number 'bad-version' in Zig SDK version index."
    result = parse_zig_versions_json(content)
    asserts.equals(env, (expected_err, None), result)

    return unittest.end(env)

_parse_zig_index_test = unittest.make(
    _parse_zig_index_test_impl,
)

def _merge_version_specs_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        {},
        merge_version_specs([]),
    )

    asserts.equals(
        env,
        {
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
        },
        merge_version_specs([
            {
                "0.12.0": {
                    "aarch64-linux": struct(
                        url = "https://ziglang.org/download/0.12.0/zig-linux-aarch64-0.12.0.tar.xz",
                        sha256 = "754f1029484079b7e0ca3b913a0a2f2a6afd5a28990cb224fe8845e72f09de63",
                    ),
                },
                "0.11.0": {
                    "aarch64-macos": struct(
                        url = "https://ziglang.org/download/0.11.0/zig-macos-aarch64-0.11.0.tar.xz",
                        sha256 = "c6ebf927bb13a707d74267474a9f553274e64906fd21bf1c75a20bde8cadf7b2",
                    ),
                },
            },
            {
                "0.11.0": {
                    "aarch64-linux": struct(
                        url = "https://ziglang.org/download/0.11.0/zig-linux-aarch64-0.11.0.tar.xz",
                        sha256 = "956eb095d8ba44ac6ebd27f7c9956e47d92937c103bf754745d0a39cdaa5d4c6",
                    ),
                },
            },
        ]),
    )

    return unittest.end(env)

_merge_version_specs_test = unittest.make(
    _merge_version_specs_test_impl,
)

def _toolchain_tag(*, zig_version, default = False, name = "", extra_exec_compatible_with = [], extra_target_compatible_with = [], extra_target_settings = []):
    return struct(
        name = name,
        zig_version = zig_version,
        default = default,
        extra_exec_compatible_with = extra_exec_compatible_with,
        extra_target_compatible_with = extra_target_compatible_with,
        extra_target_settings = extra_target_settings,
    )

def _extra_compatible_with(*, constraints = []):
    return struct(
        constraints = constraints,
    )

def _extra_target_settings(*, settings = []):
    return struct(
        settings = settings,
    )

def _toolchain_variant(*, zig_version, name = "", extra_exec_compatible_with = [], extra_target_compatible_with = [], extra_target_settings = []):
    return struct(
        name = name,
        zig_version = zig_version,
        extra_exec_compatible_with = extra_exec_compatible_with,
        extra_target_compatible_with = extra_target_compatible_with,
        extra_target_settings = extra_target_settings,
    )

def _handle_toolchain_tags(modules, *, known_versions):
    modules = [
        struct(
            is_root = mod.is_root,
            tags = struct(
                toolchain = mod.tags.toolchain,
                extra_exec_compatible_with = getattr(mod.tags, "extra_exec_compatible_with", []),
                extra_target_compatible_with = getattr(mod.tags, "extra_target_compatible_with", []),
                extra_target_settings = getattr(mod.tags, "extra_target_settings", []),
            ),
        )
        for mod in modules
    ]
    return handle_toolchain_tags(modules, known_versions = known_versions)

def _assert_toolchain_versions(env, expected, modules, *, known_versions, msg):
    result = _handle_toolchain_tags(modules, known_versions = known_versions)
    asserts.equals(env, None, result[0], msg)
    asserts.equals(env, expected, result[1], msg)

def _zig_versions_test_impl(ctx):
    env = unittest.begin(ctx)

    _assert_toolchain_versions(
        env,
        ["0.1.0"],
        [],
        known_versions = ["0.1.0"],
        msg = "should fall back to the default Zig SDK version",
    )

    asserts.equals(
        env,
        [_toolchain_variant(zig_version = "0.1.0")],
        _handle_toolchain_tags([], known_versions = ["0.1.0"])[2],
        "fallback should create one default wrapper",
    )

    _assert_toolchain_versions(
        env,
        ["0.1.0"],
        [
            struct(
                is_root = False,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.1.0"),
                    ],
                ),
            ),
        ],
        known_versions = ["0.1.0"],
        msg = "should choose a single configured version",
    )

    _assert_toolchain_versions(
        env,
        ["0.4.0", "0.2.0", "0.1.0", "0.0.1"],
        [
            struct(
                is_root = False,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.0.1"),
                        _toolchain_tag(zig_version = "0.4.0"),
                    ],
                ),
            ),
            struct(
                is_root = False,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.2.0"),
                        _toolchain_tag(zig_version = "0.1.0"),
                    ],
                ),
            ),
        ],
        known_versions = ["0.4.0", "0.2.0", "0.1.0", "0.0.1"],
        msg = "should order versions by semver",
    )

    _assert_toolchain_versions(
        env,
        ["0.1.0", "0.0.1"],
        [
            struct(
                is_root = False,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.0.1"),
                        _toolchain_tag(zig_version = "0.1.0"),
                    ],
                ),
            ),
            struct(
                is_root = False,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.0.1"),
                        _toolchain_tag(zig_version = "0.1.0"),
                    ],
                ),
            ),
        ],
        known_versions = ["0.1.0", "0.0.1"],
        msg = "should deduplicate versions",
    )

    asserts.equals(
        env,
        [
            _toolchain_variant(zig_version = "0.0.1"),
            _toolchain_variant(zig_version = "0.1.0"),
        ],
        _handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            _toolchain_tag(zig_version = "0.0.1"),
                            _toolchain_tag(zig_version = "0.1.0"),
                        ],
                    ),
                ),
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            _toolchain_tag(zig_version = "0.0.1"),
                            _toolchain_tag(zig_version = "0.1.0"),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0", "0.0.1"],
        )[2],
        "should deduplicate identical wrappers",
    )

    asserts.equals(
        env,
        [
            _toolchain_variant(
                name = "local",
                zig_version = "0.1.0",
                extra_exec_compatible_with = ["//constraints:local"],
                extra_target_compatible_with = ["//constraints:target"],
                extra_target_settings = ["//settings:enabled"],
            ),
        ],
        _handle_toolchain_tags(
            [
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [
                            _toolchain_tag(
                                name = "local",
                                zig_version = "0.1.0",
                                extra_exec_compatible_with = ["//constraints:local"],
                                extra_target_compatible_with = ["//constraints:target"],
                                extra_target_settings = ["//settings:enabled"],
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        )[2],
        "should preserve wrapper metadata",
    )

    asserts.equals(
        env,
        [
            _toolchain_variant(
                zig_version = "0.1.0",
                extra_exec_compatible_with = ["//constraints:global"],
                extra_target_compatible_with = ["//constraints:target"],
                extra_target_settings = ["//settings:global"],
            ),
        ],
        _handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            _toolchain_tag(zig_version = "0.1.0"),
                        ],
                    ),
                ),
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [],
                        extra_exec_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:global"]),
                        ],
                        extra_target_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:target"]),
                        ],
                        extra_target_settings = [
                            _extra_target_settings(settings = ["//settings:global"]),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        )[2],
        "root extras should apply to transitive toolchain tags",
    )

    asserts.equals(
        env,
        [
            _toolchain_variant(
                name = "local",
                zig_version = "0.1.0",
                extra_exec_compatible_with = [
                    "//constraints:global",
                    "//constraints:local",
                ],
                extra_target_compatible_with = [
                    "//constraints:target-global",
                    "//constraints:target-local",
                ],
                extra_target_settings = [
                    "//settings:global",
                    "//settings:local",
                ],
            ),
        ],
        _handle_toolchain_tags(
            [
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [
                            _toolchain_tag(
                                name = "local",
                                zig_version = "0.1.0",
                                extra_exec_compatible_with = ["//constraints:local"],
                                extra_target_compatible_with = ["//constraints:target-local"],
                                extra_target_settings = ["//settings:local"],
                            ),
                        ],
                        extra_exec_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:global"]),
                        ],
                        extra_target_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:target-global"]),
                        ],
                        extra_target_settings = [
                            _extra_target_settings(settings = ["//settings:global"]),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        )[2],
        "per-toolchain metadata should be appended after root extras",
    )

    asserts.equals(
        env,
        [
            _toolchain_variant(
                zig_version = "0.1.0",
                extra_exec_compatible_with = [
                    "//constraints:first",
                    "//constraints:second",
                ],
                extra_target_settings = [
                    "//settings:first",
                    "//settings:second",
                ],
            ),
        ],
        _handle_toolchain_tags(
            [
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [],
                        extra_exec_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:first"]),
                            _extra_compatible_with(constraints = ["//constraints:second"]),
                        ],
                        extra_target_settings = [
                            _extra_target_settings(settings = ["//settings:first"]),
                            _extra_target_settings(settings = ["//settings:second"]),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        )[2],
        "root extras should be additive",
    )

    asserts.equals(
        env,
        [
            _toolchain_variant(
                zig_version = "0.1.0",
                extra_exec_compatible_with = ["//constraints:global"],
                extra_target_compatible_with = ["//constraints:target-global"],
                extra_target_settings = ["//settings:global"],
            ),
        ],
        _handle_toolchain_tags(
            [
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [],
                        extra_exec_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:global"]),
                        ],
                        extra_target_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:target-global"]),
                        ],
                        extra_target_settings = [
                            _extra_target_settings(settings = ["//settings:global"]),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        )[2],
        "fallback wrapper should inherit root extras",
    )

    _assert_toolchain_versions(
        env,
        ["0.1.0", "0.4.0", "0.2.0", "0.0.1"],
        [
            struct(
                is_root = False,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.0.1"),
                        _toolchain_tag(zig_version = "0.4.0"),
                    ],
                ),
            ),
            struct(
                is_root = True,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.2.0"),
                        _toolchain_tag(zig_version = "0.1.0", default = True),
                    ],
                ),
            ),
        ],
        known_versions = ["0.4.0", "0.2.0", "0.1.0", "0.0.1"],
        msg = "the default should take precedence",
    )

    _assert_toolchain_versions(
        env,
        ["0.1.0", "0.2.0", "0.0.1"],
        [
            struct(
                is_root = False,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.0.1"),
                        _toolchain_tag(zig_version = "0.1.0"),
                    ],
                ),
            ),
            struct(
                is_root = True,
                tags = struct(
                    toolchain = [
                        _toolchain_tag(zig_version = "0.2.0"),
                        _toolchain_tag(zig_version = "0.1.0", default = True),
                    ],
                ),
            ),
        ],
        known_versions = ["0.2.0", "0.1.0", "0.0.1"],
        msg = "should not duplicate default",
    )

    asserts.equals(
        env,
        (["Only the root module may specify a default Zig SDK version.", _toolchain_tag(
            default = True,
            zig_version = "0.1.0",
        )], None, None),
        _handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [
                            _toolchain_tag(zig_version = "0.1.0", default = True),
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
        (["You may only specify one default Zig SDK version.", _toolchain_tag(
            default = True,
            zig_version = "0.2.0",
        )], None, None),
        _handle_toolchain_tags(
            [
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [
                            _toolchain_tag(zig_version = "0.1.0", default = True),
                            _toolchain_tag(zig_version = "0.2.0", default = True),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.2.0", "0.1.0"],
        ),
        "only one default allowed",
    )

    asserts.equals(
        env,
        (["Conflicting Zig SDK toolchain variant name 'local' for version '0.1.0'.", _toolchain_tag(
            name = "local",
            zig_version = "0.1.0",
            extra_target_settings = ["//settings:disabled"],
        )], None, None),
        _handle_toolchain_tags(
            [
                struct(
                    is_root = True,
                    tags = struct(
                        toolchain = [
                            _toolchain_tag(
                                name = "local",
                                zig_version = "0.1.0",
                                extra_target_settings = ["//settings:enabled"],
                            ),
                            _toolchain_tag(
                                name = "local",
                                zig_version = "0.1.0",
                                extra_target_settings = ["//settings:disabled"],
                            ),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        ),
        "conflicting duplicate wrapper metadata should fail",
    )

    asserts.equals(
        env,
        (["Only the root module may specify extra Zig SDK execution constraints.", _extra_compatible_with(
            constraints = ["//constraints:global"],
        )], None, None),
        _handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [],
                        extra_exec_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:global"]),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        ),
        "only root may set extra execution constraints",
    )

    asserts.equals(
        env,
        (["Only the root module may specify extra Zig SDK target constraints.", _extra_compatible_with(
            constraints = ["//constraints:target"],
        )], None, None),
        _handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [],
                        extra_target_compatible_with = [
                            _extra_compatible_with(constraints = ["//constraints:target"]),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        ),
        "only root may set extra target constraints",
    )

    asserts.equals(
        env,
        (["Only the root module may specify extra Zig SDK target settings.", _extra_target_settings(
            settings = ["//settings:global"],
        )], None, None),
        _handle_toolchain_tags(
            [
                struct(
                    is_root = False,
                    tags = struct(
                        toolchain = [],
                        extra_target_settings = [
                            _extra_target_settings(settings = ["//settings:global"]),
                        ],
                    ),
                ),
            ],
            known_versions = ["0.1.0"],
        ),
        "only root may set extra target settings",
    )

    return unittest.end(env)

_zig_versions_test = unittest.make(
    _zig_versions_test_impl,
)

def bzlmod_zig_test_suite(name):
    unittest.suite(
        name,
        partial.make(_zig_versions_test, size = "small"),
        partial.make(_merge_version_specs_test, size = "small"),
        partial.make(_parse_zig_index_test, size = "small"),
    )
