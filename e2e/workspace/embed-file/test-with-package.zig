const std = @import("std");
const package = @import("package");

test "embedded contents" {
    try std.testing.expectEqualStrings("Hello world!\n", package.embedded);
}
