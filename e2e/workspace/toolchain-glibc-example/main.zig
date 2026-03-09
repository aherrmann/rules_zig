const std = @import("std");
const c = @cImport({
    @cInclude("features.h");
});

extern "c" fn gnu_get_libc_version() [*c]const u8;

pub fn main() !void {
    std.debug.print("glibc compile-time version: {d}.{d}\n", .{c.__GLIBC__, c.__GLIBC_MINOR__});
    std.debug.print("glibc runtime version:      {s}\n", .{gnu_get_libc_version()});
}
