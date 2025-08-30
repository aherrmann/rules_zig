const std = @import("std");
const builtin = @import("builtin");
const c = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15)
    std.builtin.CallingConvention.c
else
    std.builtin.CallingConvention.C;

comptime {
    @export(internalName, .{
        .name = @tagName(builtin.mode),
        .linkage = if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 11)
            .Strong
        else
            .strong,
    });
}

fn internalName() callconv(c) void {}
