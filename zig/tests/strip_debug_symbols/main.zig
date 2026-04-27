const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;
const Io = if (is_zig_0_16_or_later) std.Io else void;

export fn sayHello() void {
    if (is_zig_0_16_or_later) {
        sayHelloWithIo(std.Io.Threaded.global_single_threaded.io());
    } else {
        std.fs.File.stdout().writeAll("Hello World!\n") catch unreachable;
    }
}

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() void {
    sayHello();
}

fn main_016(init: std.process.Init) void {
    sayHelloWithIo(init.io);
}

fn sayHelloWithIo(io: Io) void {
    std.Io.File.writeStreamingAll(.stdout(), io, "Hello World!\n") catch unreachable;
}

test "test" {
    try std.testing.expectEqual(2, 1 + 1);
}
