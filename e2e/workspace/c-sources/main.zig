const std = @import("std");

extern const custom_global_symbol: i32;

export fn getCustomGlobalSymbol() i32 {
    return custom_global_symbol;
}

pub fn main() !void {
    try std.io.getStdOut().writer().print("{d}\n", .{getCustomGlobalSymbol()});
}
