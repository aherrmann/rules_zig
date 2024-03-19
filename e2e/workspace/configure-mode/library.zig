const std = @import("std");
const builtin = @import("builtin");

comptime {
    @export(internalName, .{ .name = @tagName(builtin.mode), .linkage = .strong });
}

fn internalName() callconv(.C) void {}
