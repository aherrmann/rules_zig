const std = @import("std");

export fn sayHello() void {
    std.io.getStdOut().writeAll(
        "Hello World!\n",
    ) catch unreachable;
}

pub fn main() void {
    sayHello();
}

test "test" {
    try std.testing.expectEqual(2, 1 + 1);
}
