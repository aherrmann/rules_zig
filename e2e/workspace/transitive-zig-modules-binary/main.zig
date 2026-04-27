const std = @import("std");
const builtin = @import("builtin");
const hello_world = @import("hello-world");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() void {
    hello_world.sayHello();
}

fn main_016(init: std.process.Init) void {
    hello_world.sayHello_016(init);
}
