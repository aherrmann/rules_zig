const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print(
            "{s}\n",
            .{@tagName(builtin.mode)},
        );
        try stdout.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print(
            "{s}\n",
            .{@tagName(builtin.mode)},
        );
        try stdout.flush();
    }
}
