# Zig rules for Bazel

Build [Zig code][zig] with the [Bazel build system][bazel].

[zig]: https://ziglang.org/
[bazel]: https://bazel.build/

Ready to get started? Copy this repo, then

1. search for "com_myorg_rules_mylang" and replace with the name you'll use for your workspace
1. search for "myorg" and replace with GitHub org
1. search for "mylang" and replace with the language/tool your rules are for
1. rename directory "mylang" similarly
1. run `pre-commit install` to get lints (see CONTRIBUTING.md)
1. if you don't need to fetch platform-dependent tools, then remove anything toolchain-related.
1. update the `actions/cache@v2` bazel cache key in [.github/workflows/ci.yaml](.github/workflows/ci.yaml) and [.github/workflows/release.yml](.github/workflows/release.yml) to be a hash of your source files.
1. (optional) install the [Renovate app](https://github.com/apps/renovate) to get auto-PRs to keep the dependencies up-to-date.
1. delete this section of the README (everything up to the SNIP).

---- SNIP ----

# Bazel rules for Zig

## Installation

From the release you wish to use:
<https://github.com/aherrmann/rules_zig/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.
