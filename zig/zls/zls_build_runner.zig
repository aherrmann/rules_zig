const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const build_workspace_directory = try std.process.getEnvVarOwned(allocator, "BUILD_WORKSPACE_DIRECTORY");
    var child = std.process.Child.init(&.{
        "bazel",
        "run",
        "__TARGET__",
    }, allocator);
    child.cwd = build_workspace_directory;
    try child.spawn();
    _ = try child.wait();
}

fn main_016(init: std.process.Init) !void {
    const build_workspace_directory = init.environ_map.get("BUILD_WORKSPACE_DIRECTORY").?;
    var child = try std.process.spawn(init.io, .{
        .argv = &.{
            "bazel",
            "run",
            "__TARGET__",
        },
        .cwd = .{ .path = build_workspace_directory },
    });
    _ = try child.wait(init.io);
}
