const std = @import("std");

test "bazel controlled env var" {
    const attr = try std.process.getEnvVarOwned(std.testing.allocator, "ENV_ATTR");
    defer std.testing.allocator.free(attr);

    try std.testing.expectEqualStrings("42", attr);

    const result = std.process.getEnvVarOwned(std.testing.allocator, "ENV_INHERIT");

    try std.testing.expectError(error.NotSet, result);
}
