const builtin = @import("builtin");
const std = @import("std");
const elf = std.elf;

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;
const ProcessInit = if (is_zig_0_16_or_later) std.process.Init else void;

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
    var iter = try init.minimal.args.iterateAllocator(std.heap.page_allocator);
    defer iter.deinit();

    const arg0 = iter.next() orelse "read_elf_arch";
    const binary_path = iter.next() orelse {
        try printUsage_016(init.io, arg0);
        return;
    };

    try printMachineType_016(init.io, binary_path);
}

fn printUsage(arg0: []const u8) !void {
    var buffer: [512]u8 = undefined;
    var writer = std.fs.File.stderr().writer(&buffer);
    const stderr = &writer.interface;
    try stderr.print("Usage: {s} <binary_path>\n", .{arg0});
    try stderr.flush();
}

fn printUsage_016(io: anytype, arg0: []const u8) !void {
    var buffer: [512]u8 = undefined;
    var writer = std.Io.File.stderr().writer(io, &buffer);
    const stderr = &writer.interface;
    try stderr.print("Usage: {s} <binary_path>\n", .{arg0});
    try stderr.flush();
}

fn printMachineType(binary_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(binary_path, .{});
    defer file.close();
    var reader_buffer: [1024]u8 = undefined;
    var reader = file.reader(&reader_buffer);
    const elf_header = try elf.Header.read(&reader.interface);

    var buffer: [512]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    try stdout.print("{s}\n", .{@tagName(elf_header.machine)});
    try stdout.flush();
}

fn printMachineType_016(io: anytype, binary_path: []const u8) !void {
    const file = try std.Io.Dir.cwd().openFile(io, binary_path, .{});
    defer file.close(io);
    var reader_buffer: [1024]u8 = undefined;
    var reader = file.reader(io, &reader_buffer);
    const elf_header = try elf.Header.read(&reader.interface);

    var buffer: [512]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &writer.interface;
    try stdout.print("{s}\n", .{@tagName(elf_header.machine)});
    try stdout.flush();
}
