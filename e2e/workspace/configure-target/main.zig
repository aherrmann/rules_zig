const builtin = @import("builtin");
const std = @import("std");

pub fn main() !void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        try std.Io.File.writeStreamingAll(
            .stdout(),
            std.Io.Threaded.global_single_threaded.io(),
            "Hello World!\n",
        );
    } else {
        const stdout = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15)
            std.fs.File.stdout()
        else
            std.io.getStdOut();
        try stdout.writeAll(
            "Hello World!\n",
        );
    }
}
