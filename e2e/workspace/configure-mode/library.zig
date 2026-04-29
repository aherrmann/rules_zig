const std = @import("std");
const builtin = @import("builtin");
const c = std.builtin.CallingConvention.c;

comptime {
    @export(&internalName, .{
        .name = @tagName(builtin.mode),
        .linkage = .strong,
    });
}

fn internalName() callconv(c) void {}
