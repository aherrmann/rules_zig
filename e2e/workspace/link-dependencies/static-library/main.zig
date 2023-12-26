const std = @import("std");

extern fn add(u8, u8) u8;

pub fn main() !void {
    const three = add(1, 2);
    try std.io.getStdOut().writer().print("{d}\n", .{three});
}

test "One plus two equals three" {
    try std.testing.expectEqual(@as(u8, 3), add(1, 2));
}
