const builtin = @import("builtin");
const std = @import("std");

extern const symbol_a: i32;
extern const symbol_b: i32;

pub fn main() !void {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print("{d}\n", .{symbol_a + symbol_b});
        try stdout.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{d}\n", .{symbol_a + symbol_b});
        try stdout.flush();
    }
}
