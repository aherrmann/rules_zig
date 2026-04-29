const std = @import("std");
const builtin = @import("builtin");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        try printUsage(args[0]);
        return;
    }

    try printMachineType(std.heap.page_allocator, args[1]);
}

fn main_016(init: std.process.Init) !void {
    var iter = try init.minimal.args.iterateAllocator(std.heap.page_allocator);
    defer iter.deinit();

    const arg0 = iter.next() orelse "read_pe32_arch";
    const binary_path = iter.next() orelse {
        try printUsage_016(init.io, arg0);
        return;
    };

    try printMachineType_016(init.io, std.heap.page_allocator, binary_path);
}

fn printUsage(arg0: []const u8) !void {
    var buffer: [512]u8 = undefined;
    var writer = std.fs.File.stderr().writer(&buffer);
    const stderr = &writer.interface;
    try stderr.print("Usage: {s} <binary_path>\n", .{arg0});
    try stderr.flush();
}

fn printMachineType(allocator: std.mem.Allocator, binary_path: []const u8) !void {
    const content = try std.fs.cwd().readFileAlloc(allocator, binary_path, 2097152);
    defer allocator.free(content);

    var coff = try std.coff.Coff.init(content, false);
    const machine_name = @tagName(coff.getCoffHeader().machine);

    var buffer: [512]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    try stdout.print("{s}\n", .{machine_name});
    try stdout.flush();
}

fn printUsage_016(io: anytype, arg0: []const u8) !void {
    var buffer: [512]u8 = undefined;
    var writer = std.Io.File.stderr().writer(io, &buffer);
    const stderr = &writer.interface;
    try stderr.print("Usage: {s} <binary_path>\n", .{arg0});
    try stderr.flush();
}

fn printMachineType_016(io: anytype, allocator: std.mem.Allocator, binary_path: []const u8) !void {
    const file = try std.Io.Dir.cwd().openFile(io, binary_path, .{});
    defer file.close(io);
    var reader_buffer: [1024]u8 = undefined;
    var reader = file.reader(io, &reader_buffer);
    const content = try reader.interface.allocRemaining(allocator, .limited(2097152));
    defer allocator.free(content);

    var coff = try std.coff.Coff.init(content, false);
    const machine_name = switch (coff.getHeader().machine) {
        .AMD64 => "X64",
        else => |machine| @tagName(machine),
    };

    var buffer: [512]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &writer.interface;
    try stdout.print("{s}\n", .{machine_name});
    try stdout.flush();
}
