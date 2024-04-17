const std = @import("std");
const integration_testing = @import("integration_testing");
const BitContext = integration_testing.BitContext;

test "%ZIG_VERSION% - zig_binary prints Hello World!" {
    const ctx = try BitContext.init();

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{
            "run",
            "//:binary",
            "--@zig_toolchains//:version=%ZIG_VERSION%",
        },
    });
    defer result.deinit();

    try std.testing.expect(result.success);
    try std.testing.expectEqualStrings("Hello World!\n", result.stdout);
}

test "%ZIG_VERSION% - builtin.zig_version_string matches" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{
            "run",
            "//:print_zig_version",
            "--@zig_toolchains//:version=%ZIG_VERSION%",
        },
    });
    defer result.deinit();

    try std.testing.expect(result.success);
    try std.testing.expectEqualStrings("%ZIG_VERSION%", result.stdout);
}

// vim: ft=zig
