# Bazel build rules for Zig

Build [Zig code][zig] with the [Bazel build system][bazel].

[zig]: https://ziglang.org/
[bazel]: https://bazel.build/

## Status

🚧 This is a hobby project in early development. 🚧

Please [get in touch](https://github.com/aherrmann) if you would like to use
these rules in production.

Take a look at the [planned functionality][planned-functionality] tracking
issue to get a picture of which functionality is already implemented and what
is still missing.

[planned-functionality]: https://github.com/aherrmann/rules_zig/issues/1

## Installation

Add the following to your WORKSPACE file to install rules_zig:

```bzl
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_zig",
    sha256 = "$SHA256",
    strip_prefix = "rules_zig-$COMMIT",
    urls = ["https://github.com/aherrmann/rules_zig/archive/$COMMIT.tar.gz"],
)

load(
    "@rules_zig//zig:repositories.bzl",
    "rules_zig_dependencies",
    "zig_register_toolchains",
)

rules_zig_dependencies()

zig_register_toolchains(
    name = "zig",
    zig_version = "0.10.1",
)
```

<!-- TODO[AH] Point to release installation instructions

From the release you wish to use:
<https://github.com/aherrmann/rules_zig/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.

-->

<!-- TODO[AH] Write a user-guide
  https://github.com/aherrmann/rules_zig/issues/59

## User Guide Documentation

-->

## Reference Documentation

Generated API documentation for the provided rules is available in
[`./docs/rules.md`](./docs/rules.md).

## Usage Examples

<!-- TODO[AH] Create an instructive example.
  https://github.com/aherrmann/rules_zig/issues/58
-->

Examples can be found among the end-to-end tests under
[`./e2e/workspace`](./e2e/workspace).
