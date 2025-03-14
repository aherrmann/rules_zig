const std = @import("std");

test "succeeds" {
    try std.testing.expectEqual(@as(u8, 0), @as(u8, 0));
}
