const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.io.getStdOut().writer().print(
        "{s}\n",
        .{@tagName(builtin.mode)},
    ) catch unreachable;
}
