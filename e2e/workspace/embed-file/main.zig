const std = @import("std");

const embedded = @embedFile("message.txt");

pub fn main() !void {
    try std.io.getStdOut().writer().print("{s}", .{embedded});
}

test "embedded contents" {
    try std.testing.expectEqualStrings("Hello world!\n", embedded);
}
