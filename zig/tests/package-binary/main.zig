const std = @import("std");
const data = @import("data");

pub fn main() void {
    std.io.getStdOut().writeAll(
        data.hello_world,
    ) catch unreachable;
}
