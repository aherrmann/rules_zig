const builtin = @import("builtin");
const std = @import("std");
const integration_testing = @import("integration_testing.zig");
const BitContext = integration_testing.BitContext;

test "zig_binary prints Hello World!" {
    const ctx = try BitContext.init();

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    try workspace.rename("zig_version.bzl", "zig_version.bzl.backup");
    defer workspace.rename("zig_version.bzl.backup", "zig_version.bzl") catch {};

    {
        const zig_version = std.os.getenv("ZIG_VERSION").?;

        var version_file = try workspace.createFile("zig_version.bzl", .{});
        defer version_file.close();

        try version_file.writer().print("ZIG_VERSION = \"{s}\"\n", .{zig_version});
    }

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "run", "//:binary" },
    });
    defer result.deinit();

    try std.testing.expect(result.success);
    try std.testing.expectEqualStrings("Hello World!\n", result.stdout);
}
