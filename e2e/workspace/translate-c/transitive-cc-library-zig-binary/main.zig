const std = @import("std");
const module = @import("module");
const c = @import("c");
const builtin = @import("builtin");

pub fn main() !void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print("local={}\nglobal={}\n", .{ module.local(), c.global() });
        try stdout.flush();
    } else if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("local={}\nglobal={}\n", .{module.local(), c.global()});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("local={}\nglobal={}\n", .{module.local(), c.global()});
    }
}
