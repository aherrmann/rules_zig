const std = @import("std");
const indirect_package = @import("indirect-package");

test "read data file" {
    const content = try indirect_package.readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
