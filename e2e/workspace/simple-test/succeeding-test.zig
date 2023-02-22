const std = @import("std");

test "succeeds" {
    try std.testing.expectEqual(2, 1 + 1);
}
