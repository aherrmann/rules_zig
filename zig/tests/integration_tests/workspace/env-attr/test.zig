const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;
const getEnvVarOwned = if (is_zig_0_16_or_later) getEnvVarOwned_016 else getEnvVarOwned_pre_016;

fn getEnvVarOwned_pre_016(allocator: std.mem.Allocator, key: []const u8) ![]u8 {
    return try std.process.getEnvVarOwned(allocator, key);
}

fn getEnvVarOwned_016(allocator: std.mem.Allocator, key: []const u8) ![]u8 {
    return std.testing.environ.getAlloc(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableMissing => error.NotSet,
        else => |e_| return e_,
    };
}

test "bazel controlled env var" {
    const attr = try getEnvVarOwned(std.testing.allocator, "ENV_ATTR");
    defer std.testing.allocator.free(attr);

    try std.testing.expectEqualStrings("42", attr);

    const inherit = try getEnvVarOwned(std.testing.allocator, "ENV_INHERIT");
    defer std.testing.allocator.free(inherit);

    try std.testing.expectEqualStrings("21", inherit);
}
