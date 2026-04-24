const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        std.Io.File.writeStreamingAll(
            .stdout(),
            std.Io.Threaded.global_single_threaded.io(),
            "Hello World!\n",
        ) catch unreachable;
    } else {
        std.fs.File.stdout().writeAll("Hello World!\n") catch unreachable;
    }
}
