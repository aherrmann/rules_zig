const builtin = @import("builtin");
const std = @import("std");

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) ![]u8 {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        const key_z = try allocator.dupeZ(u8, key);
        defer allocator.free(key_z);
        const value = std.c.getenv(key_z.ptr) orelse return error.NotSet;
        return try allocator.dupe(u8, std.mem.span(value));
    }
    return try std.process.getEnvVarOwned(allocator, key);
}

test "bazel controlled env var" {
    const attr = try getEnvVarOwned(std.testing.allocator, "ENV_ATTR");
    defer std.testing.allocator.free(attr);

    try std.testing.expectEqualStrings("42", attr);

    const inherit = try getEnvVarOwned(std.testing.allocator, "ENV_INHERIT");
    defer std.testing.allocator.free(inherit);

    try std.testing.expectEqualStrings("21", inherit);
}
