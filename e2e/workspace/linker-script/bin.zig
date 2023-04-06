const std = @import("std");

extern const custom_global_symbol: u8;

pub fn main() !void {
    try std.io.getStdOut().writer().print("{d}\n", .{custom_global_symbol});
}
