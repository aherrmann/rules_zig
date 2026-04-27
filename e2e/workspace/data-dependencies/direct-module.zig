const std = @import("std");
const builtin = @import("builtin");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub fn readData(allocator: std.mem.Allocator) ![]u8 {
    if (is_zig_0_16_or_later) {
        const io = std.Io.Threaded.global_single_threaded.io();
        const file = try std.Io.Dir.cwd().openFile(io, "data-dependencies/data.txt", .{});
        defer file.close(io);
        var buffer: [1024]u8 = undefined;
        var reader = file.reader(io, &buffer);
        return try reader.interface.allocRemaining(allocator, .limited(4096));
    }

    var file = try std.fs.cwd().openFile("data-dependencies/data.txt", .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 4096);
}
