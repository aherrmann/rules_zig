const std = @import("std");

pub fn main() void {
    std.io.getStdOut().writeAll(
        @import("hello.zig").hello ++ " " ++ @import("world.zig").world ++ "\n",
    ) catch unreachable;
}
