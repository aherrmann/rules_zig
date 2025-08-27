const builtin = @import("builtin");
const std = @import("std");
const c = @cImport({
    @cInclude("header.h");
});

pub fn main() !void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{d}\n", .{c.THREE});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("{d}\n", .{c.THREE});
    }
}

test "One plus two equals three" {
    try std.testing.expectEqual(@as(u8, 3), c.THREE);
}
