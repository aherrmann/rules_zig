const std = @import("std");
const builtin = @import("builtin");

comptime {
    @export(internalName, .{ .name = @tagName(builtin.mode), .linkage = .Strong });
}

fn internalName() callconv(.C) void {}
