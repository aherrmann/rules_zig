const std = @import("std");

test "read data file" {
    var file = try std.fs.cwd().openFile("runfiles-library/data.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(std.testing.allocator, 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
