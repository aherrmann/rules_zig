"""Implementation of the zig_shared_library rule."""

load(
    "//zig/private/common:zig_build.bzl",
    "SHARED_LIBRARY_TOOLCHAINS",
    "zig_build_impl",
    COMMON_ATTRS = "ATTRS",
    COMMON_TOOLCHAINS = "TOOLCHAINS",
)
load(
    "//zig/private/common:zig_docs.bzl",
    "zig_docs_impl",
    DOCS_ATTRS = "ATTRS",
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
        ":my-module",  # to support `@import("my-module")`.
    ],
)
```
"""

ATTRS = COMMON_ATTRS | DOCS_ATTRS

TOOLCHAINS = COMMON_TOOLCHAINS + SHARED_LIBRARY_TOOLCHAINS

def _zig_shared_library_impl(ctx):
    build = zig_build_impl(ctx, kind = "zig_shared_library")
    docs = zig_docs_impl(ctx, kind = "zig_library")
    return build + docs

zig_shared_library = rule(
    _zig_shared_library_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = TOOLCHAINS,
)
