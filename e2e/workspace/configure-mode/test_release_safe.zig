const std = @import("std");
const builtin = @import("builtin");

test "mode is ReleaseSafe" {
    try std.testing.expectEqual(std.builtin.Mode.ReleaseSafe, builtin.mode);
}
