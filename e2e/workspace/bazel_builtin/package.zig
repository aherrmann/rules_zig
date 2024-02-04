const std = @import("std");
const bazel_builtin = @import("bazel_builtin");

pub fn testPackage() !void {
    try std.testing.expectEqualStrings("package", bazel_builtin.current_target);
    try std.testing.expectEqualStrings("bazel_builtin", bazel_builtin.current_package);
    try std.testing.expectEqualStrings("", bazel_builtin.current_repository);
}
