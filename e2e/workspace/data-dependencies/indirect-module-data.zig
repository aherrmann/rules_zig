const std = @import("std");
const indirect_module = @import("indirect-module");

test "read data file" {
    const content = try indirect_module.readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
