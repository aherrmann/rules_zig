const std = @import("std");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        try std.io.getStdErr().writer().print("Usage: {s} <binary_path>\n", .{args[0]});
        return;
    }

    try printMachineType(std.heap.page_allocator, args[1]);
}

fn printMachineType(allocator: std.mem.Allocator, binary_path: []const u8) !void {
    const content = try std.fs.cwd().readFileAlloc(allocator, binary_path, 1048576);

    var coff = try std.coff.Coff.init(content);

    try std.io.getStdOut().writer().print("{s}\n", .{@tagName(coff.getCoffHeader().machine)});
}
