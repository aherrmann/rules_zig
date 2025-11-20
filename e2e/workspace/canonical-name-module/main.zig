const builtin = @import("builtin");
const std = @import("std");
const data = @import("data");
const other_data = @import("other/data");

pub fn main() void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        std.fs.File.stdout().writeAll(
            data.hello_world,
        ) catch unreachable;
    } else {
        std.io.getStdOut().writeAll(
            data.hello_world,
        ) catch unreachable;
    }
}
