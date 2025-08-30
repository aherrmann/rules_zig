const builtin = @import("builtin");
const std = @import("std");
const c = @cImport({
    @cInclude("math.h");
});

pub fn main() !void {
    const one = c.ceil(0.5);
    const two = c.ceil(1.5);
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{d}\n", .{one + two});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("{d}\n", .{one + two});
    }
}

test "One plus two equals three" {
    const one = c.ceil(0.5);
    const two = c.ceil(1.5);
    try std.testing.expectEqual(@as(f64, 3), one + two);
}
