# How to Contribute

## Building

To build with remote execution enabled, add the following to `.bazelrc.user`:

```
build --config=remote
build --remote_header=x-buildbuddy-api-key=YOUR_TOKEN
```

To build locally instead, add the following to `.bazelrc.user`:

```
build --config=local
```

Build and test:

```
$ bazel test //...
$ bazel test //zig/tests/integration_tests
$ cd e2e/workspace; bazel test //...
```

## Committing

Follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
in pull-request titles and descriptions. These messages will be picked up by
the release automation when generating the changelog.

## Formatting

Starlark files should be formatted by buildifier.
We suggest using a pre-commit hook to automate this.
First [install pre-commit](https://pre-commit.com/#installation),
then run

```shell
pre-commit install
```

Otherwise later tooling on CI may yell at you about formatting/linting violations.

## Updating generated files

Some targets are generated from sources.
Currently these are `bzl_library` targets and `filegroup` targets.
Furthermore, the API documentation is generated, and certain flags need to be
generated for integration testing purposes.
Run `bazel run //util:update` to keep them up-to-date.

## Using this as a development dependency of other rules

You'll commonly find that you develop in another WORKSPACE, such as
some other ruleset that depends on rules_zig, or in a nested
WORKSPACE in the integration_tests folder.

To always tell Bazel to use this directory rather than some release
artifact or a version fetched from the internet, run this from this
directory:

```sh
OVERRIDE="--override_repository=rules_zig=$(pwd)/rules_zig"
echo "common $OVERRIDE" >> ~/.bazelrc
```

This means that any usage of `@rules_zig` on your system will point to this folder.

## Releasing

1. Determine the next release version, following semver (could automate in the future from changelog)
1. Tag the repo and push it (or create a tag in GH UI)
1. Watch the automation run on GitHub actions
