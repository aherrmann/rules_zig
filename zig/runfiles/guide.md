# Zig Runfiles Guide

This module provides a runfiles library for the Zig programming language: A
unified interface to discover run-time dependencies of Zig targets built by
Bazel.

Bazel manages build-time and run-time dependencies. Run-time dependencies are
typically expressed using the `data` attribute of a rule, but may come about in
other ways as well. A Bazel produced executable can be executed in a variety of
ways. For example, using the `bazel run` or `bazel test` commands, as a build
tool during the build of another target, or directly as a just built or
deployed artifact.

Run-time dependencies must be provided in a location where the executable can
discover them for all these different modes of execution and on all supported
platforms. To that end Bazel defines the [runfiles mechanism][bazel-runfiles].

The details are quite involved. To avoid error-prone repetition of the runfiles
discovery logic across components and projects, Bazel defines the [runfiles
library interface][runfiles-library] ([revised for bzlmod][runfiles-bzlmod]): A
dedicated library for each supported programming language to abstract over the
runfiles discovery mechanism.

[bazel-runfiles]: https://bazel.build/extending/rules#runfiles
[runfiles-library]: https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub
[runfiles-bzlmod]: https://github.com/bazelbuild/proposals/blob/53c5691c3f08011f0abf1d840d5824a3bbe039e2/designs/2022-07-21-locating-runfiles-with-bzlmod.md

## Documentation

Execute the following commands to build a rendered version of the `rules_zig`
runfiles user-guide and API documentation:

```console
$ bazel build @rules_zig//zig/runfiles:docs
...
Target @@rules_zig~//zig/runfiles:docs up-to-date:
  bazel-bin/external/rules_zig~/zig/runfiles/lib.docs
```

Then open the generated documentation with your browser:

```console
$ xdg-open bazel-bin/external/rules_zig~/zig/runfiles/lib.docs/index.html
```

Be sure to use the correct build output path as reported by Bazel. It may vary
between versions and from machine to machine.

## Usage

Follow the steps below to use this runfiles library in a Zig target.

1. Depend on this runfiles module from your build rule:

   ```bzl
   zig_binary(
       name = "my_binary",
       ...
       deps = ["@rules_zig//zig/runfiles"],
   )
   ```

2. Import the `runfiles` module:

   ```zig
   const runfiles = @import("runfiles");
   ```

3. Create a `runfiles.Runfiles` object using `runfiles.Runfiles.create`.

4. Define the source repository using `runfiles.Runfiles.withSourceRepo`.

5. Use `runfiles.Runfiles.WithSourceRepo.rlocation` or
   `runfiles.Runfiles.WithSourceRepo.rlocationAlloc` to look up a runfile path.

   See `runfiles.Runfiles` doctest for a worked example.
