const std = @import("std");

test "fails" {
    try std.testing.expectEqual(1, 1 + 1);
}
