const std = @import("std");
const builtin = @import("builtin");

test "match Zig version" {
    try std.testing.expectEqualStrings("0.15.2", builtin.zig_version_string);
}
