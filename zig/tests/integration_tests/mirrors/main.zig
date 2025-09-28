const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        std.fs.File.stdout().writeAll("Hello World!\n") catch unreachable;
    } else {
        std.io.getStdOut().writeAll("Hello World!\n") catch unreachable;
    }
}
