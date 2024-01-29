"""Implementation of the zig_test rule."""

load(
    "//zig/private/common:zig_build.bzl",
    "TEST_ATTRS",
    "zig_build_impl",
    COMMON_ATTRS = "ATTRS",
    COMMON_TOOLCHAINS = "TOOLCHAINS",
)

DOC = """\
Builds a Zig test.

The target can be executed using `bazel test`, corresponding to `zig test`.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_test")

zig_test(
    name = "my-test",
    main = "test.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":my-package",  # to support `@import("my-package")`.
    ],
)
```
"""

ATTRS = COMMON_ATTRS | TEST_ATTRS

TOOLCHAINS = COMMON_TOOLCHAINS

def _zig_test_impl(ctx):
    return zig_build_impl(ctx, kind = "zig_test")

zig_test = rule(
    _zig_test_impl,
    attrs = ATTRS,
    doc = DOC,
    test = True,
    toolchains = TOOLCHAINS,
)
