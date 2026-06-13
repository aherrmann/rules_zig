const std = @import("std");
const integration_testing = @import("integration_testing");
const BitContext = integration_testing.BitContext;

test "Zig package is imported from a file:// tarball" {
    const ctx = try BitContext.init();
    defer ctx.deinit();
    const allocator = std.testing.allocator;

    const fixture = try std.fs.path.join(allocator, &.{ ctx.workspace_path, "fixtures", "leaf" });
    defer allocator.free(fixture);
    const tarball = try std.fs.path.join(allocator, &.{ ctx.workspace_path, "leaf.tar" });
    defer allocator.free(tarball);

    const pack = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "run", "//tools:pack", "--", fixture, tarball },
    });
    defer pack.deinit();
    try std.testing.expect(pack.success);
    const hash = std.mem.trim(u8, pack.stdout, " \t\r\n");

    const url = try std.fmt.allocPrint(allocator, "file://{s}", .{tarball});
    defer allocator.free(url);
    try ctx.patchWorkspaceFile("build.zig.zon", &.{
        .{ "__LEAF_URL__", url },
        .{ "__LEAF_HASH__", hash },
    });

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:binary" },
    });
    defer result.deinit();
    try std.testing.expect(result.success);
}
