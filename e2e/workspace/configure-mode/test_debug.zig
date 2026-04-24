const std = @import("std");
const builtin = @import("builtin");

test "mode is Debug" {
    try std.testing.expectEqual(std.builtin.OptimizeMode.Debug, builtin.mode);
}
