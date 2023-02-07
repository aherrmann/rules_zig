const std = @import("std");
const pkg = @import("pkg");

test "1 + 3" {
    try std.testing.expectEqual(@as(i64, 4), pkg.add(1, 3));
}
