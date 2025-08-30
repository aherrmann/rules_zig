const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
            var buffer: [512]u8 = undefined;
            var writer = std.fs.File.stderr().writer(&buffer);
            const stderr = &writer.interface;
            try stderr.print("Usage: {s} <binary_path>\n", .{args[0]});
            try stderr.flush();
        } else {
            try std.io.getStdErr().writer().print("Usage: {s} <binary_path>\n", .{args[0]});
        }
        return;
    }

    try printMachineType(std.heap.page_allocator, args[1]);
}

fn printMachineType(allocator: std.mem.Allocator, binary_path: []const u8) !void {
    const content = try std.fs.cwd().readFileAlloc(allocator, binary_path, 2097152);

    var coff = if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 11)
        try std.coff.Coff.init(content)
    else
        try std.coff.Coff.init(content, false);

    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{s}\n", .{@tagName(coff.getCoffHeader().machine)});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("{s}\n", .{@tagName(coff.getCoffHeader().machine)});
    }
}
