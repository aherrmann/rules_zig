const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

export fn sayHello() void {
    if (is_zig_0_16_or_later) {
        std.Io.File.writeStreamingAll(
            .stdout(),
            std.Io.Threaded.global_single_threaded.io(),
            "Hello World!\n",
        ) catch unreachable;
    } else {
        std.fs.File.stdout().writeAll("Hello World!\n") catch unreachable;
    }
}

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() void {
    sayHello();
}

fn main_016(init: std.process.Init) void {
    sayHello();
}

test "test" {
    try std.testing.expectEqual(2, 1 + 1);
}
