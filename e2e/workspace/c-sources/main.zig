const builtin = @import("builtin");
const std = @import("std");

extern const custom_global_symbol: i32;

export fn getCustomGlobalSymbol() i32 {
    return custom_global_symbol;
}

pub fn main() !void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print("{d}\n", .{getCustomGlobalSymbol()});
        try stdout.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{d}\n", .{getCustomGlobalSymbol()});
        try stdout.flush();
    }
}
