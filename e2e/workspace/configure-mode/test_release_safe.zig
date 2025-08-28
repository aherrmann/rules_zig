const std = @import("std");
const builtin = @import("builtin");

test "mode is ReleaseSafe" {
    const release_safe = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15)
        std.builtin.OptimizeMode.ReleaseSafe
    else
        std.builtin.Mode.ReleaseSafe;
    try std.testing.expectEqual(release_safe, builtin.mode);
}
