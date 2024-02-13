"""Implementation of the zig_binary rule."""

load(
    "//zig/private/common:zig_build.bzl",
    "BINARY_ATTRS",
    "zig_build_impl",
    COMMON_ATTRS = "ATTRS",
    COMMON_TOOLCHAINS = "TOOLCHAINS",
)
load(
    "//zig/private/common:zig_docs.bzl",
    "zig_docs_impl",
)

DOC = """\
Builds a Zig binary.

The target can be built using `bazel build`, corresponding to `zig build-exe`,
and executed using `bazel run`, corresponding to `zig run`.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_binary")

zig_binary(
    name = "my-binary",
    main = "main.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":my-package",  # to support `@import("my-package")`.
    ],
)
```
"""

ATTRS = COMMON_ATTRS | BINARY_ATTRS

TOOLCHAINS = COMMON_TOOLCHAINS

def _zig_binary_impl(ctx):
    build = zig_build_impl(ctx, kind = "zig_binary")
    docs = zig_docs_impl(ctx, kind = "zig_binary")
    return build + docs

zig_binary = rule(
    _zig_binary_impl,
    attrs = ATTRS,
    doc = DOC,
    executable = True,
    toolchains = TOOLCHAINS,
)
