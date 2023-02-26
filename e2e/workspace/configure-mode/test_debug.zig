const std = @import("std");
const builtin = @import("builtin");

test "mode is Debug" {
    try std.testing.expectEqual(std.builtin.Mode.Debug, builtin.mode);
}
