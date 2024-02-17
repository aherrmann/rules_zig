const std = @import("std");
const package = @import("package");

test "package" {
    try std.testing.expectEqualStrings("Hello World!", package.message);
}
