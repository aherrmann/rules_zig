const std = @import("std");
const runfiles = @import("runfiles");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var r = try runfiles.Runfiles.create(allocator);
    defer r.deinit(allocator);

    var file = try std.fs.cwd().openFile("runfiles-library/data.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(content);

    try std.io.getStdOut().writer().print("data: {s}", .{content});
}

test "read data file" {
    var file = try std.fs.cwd().openFile("runfiles-library/data.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(std.testing.allocator, 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
