const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.io.getStdOut().writeAll(
        builtin.zig_version_string,
    ) catch unreachable;
}
