const std = @import("std");
const elf = std.elf;

pub fn main() !void {
    var args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        try std.io.getStdErr().writer().print("Usage: {s} <binary_path>\n", .{args[0]});
        return;
    }

    try printMachineType(args[1]);
}

fn printMachineType(binary_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(binary_path, .{});
    defer file.close();

    const elf_header = try elf.Header.read(file);

    try std.io.getStdOut().writer().print("{s}\n", .{@tagName(elf_header.machine)});
}
