const std = @import("std");

pub fn main() !void {
    var args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        try std.io.getStdErr().writer().print("Usage: {s} <binary_path>\n", .{args[0]});
        return;
    }

    try printMachineType(std.heap.page_allocator, args[1]);
}

fn printMachineType(allocator: std.mem.Allocator, binary_path: []const u8) !void {
    const content = try std.fs.cwd().readFileAlloc(allocator, binary_path, 1048576);

    var coff = std.coff.Coff{ .allocator = allocator };
    defer coff.deinit();

    {
        // coff.parse takes ownership of the data,
        // but does not free on error during parsing itself.
        // Note, this will be fixed in Zig 0.11.
        errdefer allocator.free(content);
        try coff.parse(content);
    }

    try std.io.getStdOut().writer().print("{s}\n", .{@tagName(coff.getCoffHeader().machine)});
}
