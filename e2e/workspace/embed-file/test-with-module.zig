const std = @import("std");
const module = @import("module");

test "embedded contents" {
    try std.testing.expectEqualStrings("Hello world!\n", module.embedded);
}
