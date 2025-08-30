const std = @import("std");
const builtin = @import("builtin");

test "mode is Debug" {
    const debug = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15)
        std.builtin.OptimizeMode.Debug
    else
        std.builtin.Mode.Debug;
    try std.testing.expectEqual(debug, builtin.mode);
}
