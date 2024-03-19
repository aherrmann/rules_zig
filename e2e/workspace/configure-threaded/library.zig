const std = @import("std");
const builtin = @import("builtin");

comptime {
    @export(internalName, .{ .name = if (builtin.single_threaded) "single_threaded" else "multi_threaded", .linkage = .strong });
}

fn internalName() callconv(.C) void {}
