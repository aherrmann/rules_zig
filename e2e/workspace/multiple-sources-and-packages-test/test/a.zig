const std = @import("std");
const pkg = @import("pkg");

test "1 + 2" {
    try std.testing.expectEqual(@as(i64, 3), pkg.add(1, 2));
}
