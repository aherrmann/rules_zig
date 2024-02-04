const std = @import("std");
const bazel_builtin = @import("bazel_builtin");

test "bazel_builtin exposes label" {
    try std.testing.expectEqualStrings("test", bazel_builtin.current_target);
    try std.testing.expectEqualStrings("bazel_builtin", bazel_builtin.current_package);
    try std.testing.expectEqualStrings("", bazel_builtin.current_repository);
}
