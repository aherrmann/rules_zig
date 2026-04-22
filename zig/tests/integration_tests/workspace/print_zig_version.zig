const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        std.Io.File.writeStreamingAll(
            .stdout(),
            std.Io.Threaded.global_single_threaded.io(),
            builtin.zig_version_string,
        ) catch unreachable;
    } else if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        std.fs.File.stdout().writeAll(
            builtin.zig_version_string,
        ) catch unreachable;
    } else {
        std.io.getStdOut().writeAll(
            builtin.zig_version_string,
        ) catch unreachable;
    }
}
