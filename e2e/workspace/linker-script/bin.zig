const builtin = @import("builtin");
const std = @import("std");

extern const custom_global_symbol: u8;

pub fn main() !void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{d}\n", .{custom_global_symbol});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("{d}\n", .{custom_global_symbol});
    }
}
