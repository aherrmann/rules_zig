const std = @import("std");

test "fails" {
    try std.testing.expectEqual(@as(u8, 1), @as(u8, 0));
}
