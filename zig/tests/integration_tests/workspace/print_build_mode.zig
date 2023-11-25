const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.io.getStdOut().writeAll(
        @tagName(builtin.mode),
    ) catch unreachable;
}
