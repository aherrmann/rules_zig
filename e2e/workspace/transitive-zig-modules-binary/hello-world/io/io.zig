const std = @import("std");

pub fn print(msg: []const u8) void {
    std.io.getStdOut().writeAll(msg) catch unreachable;
}
