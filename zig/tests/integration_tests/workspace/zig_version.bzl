"""Defines the Zig SDK version to use for integration tests."""

load("@rules_zig//zig/private:versions.bzl", "LATEST_RELEASE")

ZIG_VERSION = LATEST_RELEASE
