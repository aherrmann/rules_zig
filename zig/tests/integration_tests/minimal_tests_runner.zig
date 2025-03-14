const builtin = @import("builtin");
const std = @import("std");
const integration_testing = @import("integration_testing");
const BitContext = integration_testing.BitContext;

test "zig_test passes" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "test", "//:test" },
    });
    defer result.deinit();

    try std.testing.expect(result.success);
}
