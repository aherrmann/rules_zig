const std = @import("std");

test "bazel controlled env var" {
    const attr = try std.process.getEnvVarOwned(std.testing.allocator, "ENV_ATTR");
    defer std.testing.allocator.free(attr);

    try std.testing.expectEqualStrings("42", attr);

    const inherit = try std.process.getEnvVarOwned(std.testing.allocator, "ENV_INHERIT");
    defer std.testing.allocator.free(inherit);

    try std.testing.expectEqualStrings("21", inherit);
}
