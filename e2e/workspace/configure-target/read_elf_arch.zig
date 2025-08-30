const builtin = @import("builtin");
const std = @import("std");
const elf = std.elf;

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

    try printMachineType(args[1]);
}

fn printMachineType(binary_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(binary_path, .{});
    defer file.close();

    const elf_header = header: {
        if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
            var buffer: [1024]u8 = undefined;
            var reader = file.reader(&buffer);
            break :header try elf.Header.read(&reader.interface);
        } else {
            break :header try elf.Header.read(file);
        }
    };

    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{s}\n", .{@tagName(elf_header.machine)});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("{s}\n", .{@tagName(elf_header.machine)});
    }
}
