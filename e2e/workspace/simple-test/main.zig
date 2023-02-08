const std = @import("std");

test "simple" {
    try std.testing.expectEqual(2, 1 + 1);
}
