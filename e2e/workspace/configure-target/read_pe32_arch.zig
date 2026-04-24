const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
            var buffer: [512]u8 = undefined;
            var writer = std.Io.File.stderr().writer(
                std.Io.Threaded.global_single_threaded.io(),
                &buffer,
            );
            const stderr = &writer.interface;
            try stderr.print("Usage: {s} <binary_path>\n", .{args[0]});
            try stderr.flush();
        } else {
            var buffer: [512]u8 = undefined;
            var writer = std.fs.File.stderr().writer(&buffer);
            const stderr = &writer.interface;
            try stderr.print("Usage: {s} <binary_path>\n", .{args[0]});
            try stderr.flush();
        }
        return;
    }

    try printMachineType(std.heap.page_allocator, args[1]);
}

fn printMachineType(allocator: std.mem.Allocator, binary_path: []const u8) !void {
    const content = try std.fs.cwd().readFileAlloc(allocator, binary_path, 2097152);

    var coff = try std.coff.Coff.init(content, false);

    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print("{s}\n", .{@tagName(coff.getCoffHeader().machine)});
        try stdout.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{s}\n", .{@tagName(coff.getCoffHeader().machine)});
        try stdout.flush();
    }
}
