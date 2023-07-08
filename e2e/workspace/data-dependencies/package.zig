const std = @import("std");

pub fn readData(allocator: std.mem.Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile("data-dependencies/data.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 4096);

    return content;
}
