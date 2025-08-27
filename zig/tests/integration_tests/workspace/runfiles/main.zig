const builtin = @import("builtin");
const std = @import("std");
const runfiles = @import("runfiles");
const bazel_builtin = @import("bazel_builtin");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var r_ = try runfiles.Runfiles.create(.{ .allocator = allocator }) orelse
        return error.RunfilesNotFound;
    defer r_.deinit(allocator);

    const r = r_.withSourceRepo(bazel_builtin.current_repository);

    const rpath = "integration_tests/runfiles/data.txt";

    const file_path = try r.rlocationAlloc(allocator, rpath) orelse {
        std.log.err("Runfiles location '{s}' not found", .{rpath});
        return error.RLocationNotFound;
    };
    defer allocator.free(file_path);

    const file = std.fs.cwd().openFile(file_path, .{}) catch |e| {
        std.log.err("Failed to open file '{s}': {}", .{ file_path, e });
        return e;
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(content);

    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("data: {s}", .{content});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("data: {s}", .{content});
    }
}
