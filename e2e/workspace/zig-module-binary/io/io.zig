const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;
const Io = if (is_zig_0_16_or_later) std.Io else void;

pub fn print(msg: []const u8) void {
    if (is_zig_0_16_or_later) {
        printWithIo(std.Io.Threaded.global_single_threaded.io(), msg);
    } else {
        std.fs.File.stdout().writeAll(msg) catch unreachable;
    }
}

pub fn printWithIo(io: Io, msg: []const u8) void {
    std.Io.File.writeStreamingAll(.stdout(), io, msg) catch unreachable;
}
