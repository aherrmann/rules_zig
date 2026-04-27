const builtin = @import("builtin");
const std = @import("std");
const runfiles = @import("runfiles");
const bazel_builtin = @import("bazel_builtin");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var r_ = try runfiles.Runfiles.create(if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16)
        .{
            .allocator = allocator,
            .io = std.Io.Threaded.global_single_threaded.io(),
            .argv0 = "bazel-bin/runfiles/binary",
        }
    else
        .{ .allocator = allocator }) orelse
        return error.RunfilesNotFound;
    defer r_.deinit(allocator);

    const r = r_.withSourceRepo(bazel_builtin.current_repository);

    const rpath = "integration_tests/runfiles/data.txt";

    const file_path = try r.rlocationAlloc(allocator, rpath) orelse {
        std.log.err("Runfiles location '{s}' not found", .{rpath});
        return error.RLocationNotFound;
    };
    defer allocator.free(file_path);

    const content = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) content: {
        const io = std.Io.Threaded.global_single_threaded.io();
        const file = std.Io.Dir.openFileAbsolute(io, file_path, .{}) catch |e| {
            std.log.err("Failed to open file '{s}': {}", .{ file_path, e });
            return e;
        };
        defer file.close(io);

        var buffer: [4096]u8 = undefined;
        var reader = file.reader(io, &buffer);
        break :content try reader.interface.allocRemaining(allocator, .limited(4096));
    } else content: {
        const file = std.fs.cwd().openFile(file_path, .{}) catch |e| {
            std.log.err("Failed to open file '{s}': {}", .{ file_path, e });
            return e;
        };
        defer file.close();

        break :content try file.readToEndAlloc(allocator, 4096);
    };
    defer allocator.free(content);

    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print("data: {s}", .{content});
        try stdout.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("data: {s}", .{content});
        try stdout.flush();
    }
}
