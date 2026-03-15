const std = @import("std");
const c = @cImport({
    @cInclude("features.h");
});

extern "c" fn gnu_get_libc_version() [*c]const u8;

pub fn main() !void {
    std.debug.print("glibc compile-time version: {d}.{d}\n", .{ c.__GLIBC__, c.__GLIBC_MINOR__ });
    std.debug.print("glibc runtime version:      {s}\n", .{gnu_get_libc_version()});
}

test "test_fallback_glibc.2.17" {
    try std.testing.expectEqual(2, c.__GLIBC__);
    try std.testing.expectEqual(17, c.__GLIBC_MINOR__);
}
