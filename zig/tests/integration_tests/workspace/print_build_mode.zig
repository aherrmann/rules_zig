const builtin = @import("builtin");
const std = @import("std");

pub fn main() void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        std.fs.File.stdout().writeAll(
            @tagName(builtin.mode),
        ) catch unreachable;
    } else {
        std.io.getStdOut().writeAll(
            @tagName(builtin.mode),
        ) catch unreachable;
    }
}
