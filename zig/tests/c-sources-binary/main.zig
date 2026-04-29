const builtin = @import("builtin");
const std = @import("std");

extern const symbol_a: i32;
extern const symbol_b: i32;

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() !void {
    var buffer: [512]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    try stdout.print("{d}\n", .{symbol_a + symbol_b});
    try stdout.flush();
}

fn main_016(init: std.process.Init) !void {
    var buffer: [512]u8 = undefined;
    var writer = std.Io.File.stdout().writer(init.io, &buffer);
    const stdout = &writer.interface;
    try stdout.print("{d}\n", .{symbol_a + symbol_b});
    try stdout.flush();
}
