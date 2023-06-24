const std = @import("std");

extern const symbol_a: i32;
extern const symbol_b: i32;

pub fn main() !void {
    try std.io.getStdOut().writer().print("{d}\n", .{symbol_a + symbol_b});
}
