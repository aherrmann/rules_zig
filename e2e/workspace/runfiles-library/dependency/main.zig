const std = @import("std");
const builtin = @import("builtin");
const runfiles = @import("runfiles");
const bazel_builtin = @import("bazel_builtin");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

fn createTestingRunfiles(allocator: std.mem.Allocator) !?runfiles.Runfiles {
    if (is_zig_0_16_or_later) {
        var env_map = try std.process.Environ.createMap(std.testing.environ, allocator);
        defer env_map.deinit();
        return try runfiles.Runfiles.create(.{
            .allocator = allocator,
            .io = std.testing.io,
            .environ_map = &env_map,
        });
    }
    return try runfiles.Runfiles.create(.{ .allocator = allocator });
}

fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8, limit: usize) ![]u8 {
    if (is_zig_0_16_or_later) {
        const io = std.testing.io;
        const file = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file.close(io);
        var buffer: [1024]u8 = undefined;
        var reader = file.reader(io, &buffer);
        return try reader.interface.allocRemaining(allocator, .limited(limit));
    }

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, limit);
}

pub fn readData(allocator: std.mem.Allocator) ![]const u8 {
    var r_ = try createTestingRunfiles(allocator) orelse
        return error.RunfilesNotFound;
    defer r_.deinit(allocator);

    const r = r_.withSourceRepo(bazel_builtin.current_repository);

    const rpath = "runfiles_library_transitive_dependency/data.txt";

    const file_path = try r.rlocationAlloc(allocator, rpath) orelse
        return error.RLocationNotFound;
    defer allocator.free(file_path);

    return try readFileAlloc(allocator, file_path, 4096);
}

test "read data file in dependency module" {
    const content = try readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello from transitive dependency!\n", content);
}
