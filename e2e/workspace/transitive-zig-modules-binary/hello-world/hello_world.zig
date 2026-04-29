const std = @import("std");
const builtin = @import("builtin");
const data = @import("data");
const io = @import("io");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub fn sayHello() void {
    io.print(data.hello_world);
}

pub fn sayHello_016(init: std.process.Init) void {
    std.Io.File.writeStreamingAll(.stdout(), init.io, data.hello_world) catch unreachable;
}
