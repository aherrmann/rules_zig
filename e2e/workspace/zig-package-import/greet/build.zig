const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const clap = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("greet", .{
        .root_source_file = b.path("src/greet.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("clap", clap.module("clap"));
}
