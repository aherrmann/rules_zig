const builtin = @import("builtin");
const std = @import("std");

export fn sayHello() void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        std.Io.File.writeStreamingAll(
            .stdout(),
            std.Io.Threaded.global_single_threaded.io(),
            "Hello World!\n",
        ) catch unreachable;
    } else {
        std.fs.File.stdout().writeAll(
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
