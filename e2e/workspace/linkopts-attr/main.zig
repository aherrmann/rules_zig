
const builtin = @import("builtin");
const std = @import("std");

extern fn rand() u32;

pub fn main() void {
    _ = rand();
}

test "test" {
    try std.testing.expect(rand() >= 0);
}
