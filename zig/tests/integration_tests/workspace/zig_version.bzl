"""Defines the Zig SDK version to use for integration tests."""

load("@rules_zig//zig/private:versions.bzl", "TOOL_VERSIONS")

ZIG_VERSION = TOOL_VERSIONS.keys()[0]
