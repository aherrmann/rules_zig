const builtin = @import("builtin");
const std = @import("std");

export fn sayHello() void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        std.fs.File.stdout().writeAll(
            "Hello World!\n",
        ) catch unreachable;
    } else {
        std.io.getStdOut().writeAll(
            "Hello World!\n",
        ) catch unreachable;
    }
}

pub fn main() void {
    sayHello();
}

test "test" {
    try std.testing.expectEqual(2, 1 + 1);
}
