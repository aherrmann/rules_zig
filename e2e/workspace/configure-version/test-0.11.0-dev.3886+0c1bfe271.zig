const std = @import("std");
const builtin = @import("builtin");

test "match Zig version" {
    try std.testing.expectEqualStrings("0.11.0-dev.3886+0c1bfe271", builtin.zig_version_string);
}
