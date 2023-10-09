"""Implementation of the zig_shared_library rule."""

load(
    "//zig/private/common:zig_build.bzl",
    "zig_build_impl",
    COMMON_ATTRS = "ATTRS",
    COMMON_TOOLCHAINS = "TOOLCHAINS",
)

DOC = """\
Builds a Zig shared library.

The target can be built using `bazel build`, corresponding to `zig build-lib`.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_shared_library")

zig_shared_library(
    name = "my-library",
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

ATTRS = COMMON_ATTRS

TOOLCHAINS = COMMON_TOOLCHAINS

def _zig_shared_library_impl(ctx):
    return zig_build_impl(ctx, kind = "zig_shared_library")

zig_shared_library = rule(
    _zig_shared_library_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = TOOLCHAINS,
)
