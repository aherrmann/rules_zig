const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub fn print(msg: []const u8) void {
    if (is_zig_0_16_or_later) {
        std.Io.File.writeStreamingAll(
            .stdout(),
            std.Io.Threaded.global_single_threaded.io(),
            msg,
        ) catch unreachable;
    } else {
        std.fs.File.stdout().writeAll(msg) catch unreachable;
    }
}
