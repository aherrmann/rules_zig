const std = @import("std");
const builtin = @import("builtin");

test "single_threaded is true" {
    try std.testing.expect(builtin.single_threaded);
}
