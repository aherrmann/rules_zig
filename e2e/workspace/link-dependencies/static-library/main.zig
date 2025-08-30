const builtin = @import("builtin");
const std = @import("std");

extern fn add(u8, u8) u8;

pub fn main() !void {
    const three = add(1, 2);
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{d}\n", .{three});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("{d}\n", .{three});
    }
}

test "One plus two equals three" {
    try std.testing.expectEqual(@as(u8, 3), add(1, 2));
}
