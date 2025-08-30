const builtin = @import("builtin");
const std = @import("std");

const embedded = @embedFile("message.txt");

pub fn main() !void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{s}", .{embedded});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("{s}", .{embedded});
    }
}

test "embedded contents" {
    try std.testing.expectEqualStrings("Hello world!\n", embedded);
}
