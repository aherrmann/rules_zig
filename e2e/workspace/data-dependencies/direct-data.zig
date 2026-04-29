const std = @import("std");
const builtin = @import("builtin");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8, limit: usize) ![]u8 {
    if (is_zig_0_16_or_later) {
        const io = std.testing.io;
        const file = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file.close(io);
        var buffer: [1024]u8 = undefined;
        var reader = file.reader(io, &buffer);
        return try reader.interface.allocRemaining(allocator, .limited(limit));
    }

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, limit);
}

test "read data file" {
    const content = try readFileAlloc(std.testing.allocator, "data-dependencies/data.txt", 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
