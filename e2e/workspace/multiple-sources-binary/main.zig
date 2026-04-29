const std = @import("std");
const builtin = @import("builtin");
const data = @import("data.zig");
const io = @import("io.zig");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() void {
    io.print(data.hello_world);
}

fn main_016(init: std.process.Init) void {
    std.Io.File.writeStreamingAll(.stdout(), init.io, data.hello_world) catch unreachable;
}
