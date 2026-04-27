const builtin = @import("builtin");
const std = @import("std");
const elf = std.elf;

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;
const ProcessInit = if (is_zig_0_16_or_later) std.process.Init.Minimal else void;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        try printUsage(args[0]);
        return;
    }

    try printMachineType(args[1]);
}

fn main_016(init: ProcessInit) !void {
    var iter = try init.args.iterateAllocator(std.heap.page_allocator);
    defer iter.deinit();

    const arg0 = iter.next() orelse "read_elf_arch";
    const binary_path = iter.next() orelse {
        try printUsage(arg0);
        return;
    };

    try printMachineType(binary_path);
}

fn printUsage(arg0: []const u8) !void {
    if (is_zig_0_16_or_later) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stderr().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stderr = &writer.interface;
        try stderr.print("Usage: {s} <binary_path>\n", .{arg0});
        try stderr.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stderr().writer(&buffer);
        const stderr = &writer.interface;
        try stderr.print("Usage: {s} <binary_path>\n", .{arg0});
        try stderr.flush();
    }
}

fn printMachineType(binary_path: []const u8) !void {
    const elf_header = header: {
        if (is_zig_0_16_or_later) {
            const io = std.Io.Threaded.global_single_threaded.io();
            const file = try std.Io.Dir.cwd().openFile(io, binary_path, .{});
            defer file.close(io);
            var buffer: [1024]u8 = undefined;
            var reader = file.reader(io, &buffer);
            break :header try elf.Header.read(&reader.interface);
        } else {
            const file = try std.fs.cwd().openFile(binary_path, .{});
            defer file.close();
            var buffer: [1024]u8 = undefined;
            var reader = file.reader(&buffer);
            break :header try elf.Header.read(&reader.interface);
        }
    };

    if (is_zig_0_16_or_later) {
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
