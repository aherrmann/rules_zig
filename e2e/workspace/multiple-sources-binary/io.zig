const builtin = @import("builtin");
const std = @import("std");

pub fn print(msg: []const u8) void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        std.Io.File.writeStreamingAll(
            .stdout(),
            std.Io.Threaded.global_single_threaded.io(),
            msg,
        ) catch unreachable;
    } else if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        std.fs.File.stdout().writeAll(msg) catch unreachable;
    } else {
        std.io.getStdOut().writeAll(msg) catch unreachable;
    }
}
