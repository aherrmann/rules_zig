const std = @import("std");
const builtin = @import("builtin");

comptime {
    @export(internalName, .{
        .name = @tagName(builtin.mode),
        .linkage = if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 11)
            .Strong
        else
            .strong,
    });
}

fn internalName() callconv(.C) void {}
