const std = @import("std");

pub fn build(b: *std.Build) void {
    const cdep = b.addModule("cdep", .{
        .root_source_file = b.path("src/cdep.zig"),
    });
    cdep.addCSourceFile(.{
        .file = b.path("src/value.c"),
        .flags = &.{"-DSCALE=3"},
    });
    cdep.addCSourceFile(.{
        .file = b.path("src/other.c"),
        .flags = &.{"-DSCALE=7"},
    });
    cdep.addIncludePath(b.path("include"));
}
