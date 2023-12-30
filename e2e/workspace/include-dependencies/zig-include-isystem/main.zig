const std = @import("std");
const c = @cImport({
    @cInclude("header.h");
});

pub fn main() !void {
    try std.io.getStdOut().writer().print("{d}\n", .{c.THREE});
}

test "One plus two equals three" {
    try std.testing.expectEqual(@as(u8, 3), c.THREE);
}
