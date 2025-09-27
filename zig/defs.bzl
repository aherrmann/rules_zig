"""Rules to build and run Zig code.

Note, all Zig targets implicitly depend on an automatically generated Zig
module called `bazel_builtin` that exposes Bazel specific information such as
the current target name or current repository name.
"""

load("//zig/private:zig_binary.bzl", _zig_binary = "zig_binary")
load("//zig/private:zig_c_library.bzl", _zig_c_library = "zig_c_library")
load(
    "//zig/private:zig_configure.bzl",
    _zig_configure = "zig_configure",
    _zig_configure_binary = "zig_configure_binary",
    _zig_configure_test = "zig_configure_test",
)
load("//zig/private:zig_library.bzl", _zig_library = "zig_library")
load("//zig/private:zig_shared_library.bzl", _zig_shared_library = "zig_shared_library")
load("//zig/private:zig_static_library.bzl", _zig_static_library = "zig_static_library")
load("//zig/private:zig_test.bzl", _zig_test = "zig_test")

zig_binary = _zig_binary
zig_static_library = _zig_static_library
zig_shared_library = _zig_shared_library
zig_library = _zig_library
zig_c_library = _zig_c_library
zig_test = _zig_test
zig_configure = _zig_configure
zig_configure_binary = _zig_configure_binary
zig_configure_test = _zig_configure_test

def zig_module(*, name, **kwargs):
    """Alias for `zig_library`.

    Args:
      name: string, a unique name for the rule.
      **kwargs: keyword arguments to forward to `zig_library`.

    Deprecated:
      The `zig_module` rule is deprecated, use `zig_library` instead.
    """
    target = native.package_relative_label(name)
    package = native.package_relative_label("__pkg__")

    # buildifier: disable=print
    print("""\
The `zig_module` rule is deprecated, use `zig_library` instead.
You can use the following buildozer commands to fix it.
buildozer 'fix movePackageToTop' {package}
buildozer 'set kind zig_library' {target}
buildozer 'new_load @rules_zig//zig:defs.bzl zig_library' {package}
buildozer 'fix unusedLoads' {package}
""".format(
        target = target,
        package = package,
    ))
    zig_library(name = name, **kwargs)

def zig_c_module(*, name, **kwargs):
    """Alias for `zig_c_library`.

    Args:
      name: string, a unique name for the rule.
      **kwargs: keyword arguments to forward to `zig_c_library`.

    Deprecated:
      The `zig_c_module` rule is deprecated, use `zig_c_library` instead.
    """
    target = native.package_relative_label(name)
    package = native.package_relative_label("__pkg__")

    # buildifier: disable=print
    print("""\
The `zig_c_module` rule is deprecated, use `zig_c_library` instead.
You can use the following buildozer commands to fix it.
buildozer 'fix movePackageToTop' {package}
buildozer 'set kind zig_c_library' {target}
buildozer 'new_load @rules_zig//zig:defs.bzl zig_c_library' {package}
buildozer 'fix unusedLoads' {package}
""".format(
        target = target,
        package = package,
    ))
    zig_c_library(name = name, **kwargs)
