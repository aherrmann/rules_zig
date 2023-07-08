const std = @import("std");
const package = @import("package");

test "read data file" {
    const content = try package.readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
