"""Rules to build and run Zig code.

Note, all Zig targets implicitly depend on an automatically generated Zig
module called `bazel_builtin` that exposes Bazel specific information such as
the current target name or current repository name.
"""

load("//zig/private:zig_binary.bzl", _zig_binary = "zig_binary")
load(
    "//zig/private:zig_configure.bzl",
    _zig_configure = "zig_configure",
    _zig_configure_binary = "zig_configure_binary",
    _zig_configure_test = "zig_configure_test",
)
load("//zig/private:zig_library.bzl", _zig_library = "zig_library")
load("//zig/private:zig_module.bzl", _zig_module = "zig_module")
load("//zig/private:zig_shared_library.bzl", _zig_shared_library = "zig_shared_library")
load("//zig/private:zig_test.bzl", _zig_test = "zig_test")

zig_binary = _zig_binary
zig_library = _zig_library
zig_shared_library = _zig_shared_library
zig_module = _zig_module
zig_test = _zig_test
zig_configure = _zig_configure
zig_configure_binary = _zig_configure_binary
zig_configure_test = _zig_configure_test

def zig_package(**kwargs):
    """Alias for `zig_module`.

    Deprecated: The `zig_package` rule is deprecated, use `zig_module` instead.
    """

    # buildifier: disable=print
    print("The `zig_package` rule is deprecated, use `zig_module` instead.")
    zig_module(**kwargs)
