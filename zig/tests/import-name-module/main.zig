const builtin = @import("builtin");
const std = @import("std");
const data = @import("import-name-module/data");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() void {
    std.fs.File.stdout().writeAll(data.hello_world) catch unreachable;
}

fn main_016(init: std.process.Init) void {
    std.Io.File.writeStreamingAll(.stdout(), init.io, data.hello_world) catch unreachable;
}
