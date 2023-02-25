const std = @import("std");

test "test" {
    try std.testing.expectEqual(2, 1 + 1);
}
