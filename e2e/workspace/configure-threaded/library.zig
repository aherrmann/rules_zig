const std = @import("std");
const builtin = @import("builtin");
const c = std.builtin.CallingConvention.c;

comptime {
    @export(&internalName, .{
        .name = if (builtin.single_threaded) "single_threaded" else "multi_threaded",
        .linkage = .strong,
    });
}

fn internalName() callconv(c) void {}
