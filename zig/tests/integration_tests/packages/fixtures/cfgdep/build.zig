const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const cfgdep = b.addModule("cfgdep", .{
        .root_source_file = b.path("src/cfgdep.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = optimize,
    });
    if (optimize == .Debug) {
        cfgdep.linkSystemLibrary("dbgonly", .{});
    } else {
        cfgdep.linkSystemLibrary("relonly", .{});
    }
}
