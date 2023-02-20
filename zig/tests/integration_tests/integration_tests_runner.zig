const std = @import("std");

test "dummy" {
    try std.testing.expectEqual(@as(u8, 0), @as(u8, 1));
}
