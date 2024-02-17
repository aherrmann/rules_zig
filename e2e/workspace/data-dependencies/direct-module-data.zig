const std = @import("std");
const direct_module = @import("direct-module");

test "read data file" {
    const content = try direct_module.readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
