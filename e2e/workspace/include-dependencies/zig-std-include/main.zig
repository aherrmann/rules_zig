const std = @import("std");
const c = @cImport({
    @cInclude("math.h");
});

pub fn main() !void {
    const one = c.ceil(0.5);
    const two = c.ceil(1.5);
    try std.io.getStdOut().writer().print("{d}\n", .{one + two});
}

test "One plus two equals three" {
    const one = c.ceil(0.5);
    const two = c.ceil(1.5);
    try std.testing.expectEqual(@as(f64, 3), one + two);
}
