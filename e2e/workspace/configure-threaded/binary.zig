const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.io.getStdOut().writer().print(
        "{}\n",
        .{builtin.single_threaded},
    ) catch unreachable;
}
