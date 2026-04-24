const builtin = @import("builtin");
const std = @import("std");
const elf = std.elf;

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

    try printMachineType(args[1]);
}

fn printMachineType(binary_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(binary_path, .{});
    defer file.close();

    const elf_header = header: {
        if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
            var buffer: [1024]u8 = undefined;
            var reader = file.reader(
                std.Io.Threaded.global_single_threaded.io(),
                &buffer,
            );
            break :header try elf.Header.read(&reader.interface);
        } else {
            var buffer: [1024]u8 = undefined;
            var reader = file.reader(&buffer);
            break :header try elf.Header.read(&reader.interface);
        }
    };

    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print("{s}\n", .{@tagName(elf_header.machine)});
        try stdout.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{s}\n", .{@tagName(elf_header.machine)});
        try stdout.flush();
    }
}
