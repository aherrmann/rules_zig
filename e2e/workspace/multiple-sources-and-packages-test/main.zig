const std = @import("std");
const pkg = @import("pkg");

test "1 + 1" {
    try std.testing.expectEqual(@as(i64, 2), pkg.add(1, 1));
}

test {
    _ = @import("test/a.zig");
    _ = @import("test/b.zig");
}
