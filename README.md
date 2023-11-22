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

## Motivation

Why would you use Bazel to build Zig code,
when Zig comes with its own perfectly fine [build system][zig-build]?

These Bazel rules are not meant as competition to the Zig build system.
If your project fits well within the scope of Zig's build system,
in particular, it only uses Zig code and perhaps C/C++ code,
then Zig's build system will probably work very well for your use-case.

Bazel is useful for polyglot, monorepo projects,
especially if they are very large.
If your project involves multiple programming languages
and if some of them are not supported by Zig's build system,
or if your project involves complex code-generation steps
or requires a lot of [custom build steps][zig-build-command-step],
then Bazel may be a good choice.
If your project is already a Bazel project
and you want to add Zig code to it
then this rule set is for you.

Bazel has builtin support for [cross-compilation][bazel-platforms]
and [build configuration][bazel-configurations],
meaning it can support Zig's cross-compilation
and build configuration features well.

[zig-build]: https://ziglang.org/documentation/master/#Zig-Build-System
[zig-build-command-step]: https://ikrima.dev/dev-notes/zig/zig-build/#run-commands-as-build-steps
[bazel-platforms]: https://bazel.build/extending/platforms
[bazel-configurations]: https://bazel.build/extending/config

## Installation

### Using Bzlmod with Bazel >=6

Add the following to your MODULE.bazel file to install rules_zig:

```bzl
bazel_dep(name = "rules_zig")
archive_override(
    module_name = "rules_zig",
    integrity = "sha256-$SHA256",
    strip_prefix = "rules_zig-$COMMIT",
    urls = ["https://github.com/aherrmann/rules_zig/archive/$COMMIT.tar.gz"],
)
```

### Using WORKSPACE

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
    zig_version = "0.11.0",
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
