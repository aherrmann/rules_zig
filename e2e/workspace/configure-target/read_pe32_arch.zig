const std = @import("std");
const builtin = @import("builtin");

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

    try printMachineType(std.heap.page_allocator, args[1]);
}

fn main_016(init: ProcessInit) !void {
    var iter = try init.args.iterateAllocator(std.heap.page_allocator);
    defer iter.deinit();

    const arg0 = iter.next() orelse "read_pe32_arch";
    const binary_path = iter.next() orelse {
        try printUsage(arg0);
        return;
    };

    try printMachineType(std.heap.page_allocator, binary_path);
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

fn printMachineType(allocator: std.mem.Allocator, binary_path: []const u8) !void {
    const content = if (is_zig_0_16_or_later) content: {
        const io = std.Io.Threaded.global_single_threaded.io();
        const file = try std.Io.Dir.cwd().openFile(io, binary_path, .{});
        defer file.close(io);
        var buffer: [1024]u8 = undefined;
        var reader = file.reader(io, &buffer);
        break :content try reader.interface.allocRemaining(allocator, .limited(2097152));
    } else try std.fs.cwd().readFileAlloc(allocator, binary_path, 2097152);
    defer allocator.free(content);

    var coff = try std.coff.Coff.init(content, false);
    const machine_name = if (is_zig_0_16_or_later)
        switch (coff.getHeader().machine) {
            .AMD64 => "X64",
            else => |machine| @tagName(machine),
        }
    else
        @tagName(coff.getCoffHeader().machine);

    if (is_zig_0_16_or_later) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print("{s}\n", .{machine_name});
        try stdout.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{s}\n", .{machine_name});
        try stdout.flush();
    }
}
