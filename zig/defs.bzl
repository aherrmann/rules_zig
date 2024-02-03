"Rules to build and run Zig code."

load("//zig/private:zig_binary.bzl", _zig_binary = "zig_binary")
load(
    "//zig/private:zig_configure.bzl",
    _zig_configure = "zig_configure",
    _zig_configure_binary = "zig_configure_binary",
    _zig_configure_test = "zig_configure_test",
)
load("//zig/private:zig_library.bzl", _zig_library = "zig_library")
load("//zig/private:zig_package.bzl", _zig_package = "zig_package")
load("//zig/private:zig_runfiles.bzl", _zig_runfiles = "zig_runfiles")
load("//zig/private:zig_shared_library.bzl", _zig_shared_library = "zig_shared_library")
load("//zig/private:zig_test.bzl", _zig_test = "zig_test")

zig_binary = _zig_binary
zig_library = _zig_library
zig_shared_library = _zig_shared_library
zig_package = _zig_package
zig_runfiles = _zig_runfiles
zig_test = _zig_test
zig_configure = _zig_configure
zig_configure_binary = _zig_configure_binary
zig_configure_test = _zig_configure_test
