const std = @import("std");

pub fn build(b: *std.Build) void {
    const widget = b.addModule("widget", .{ .root_source_file = b.path("src/widget.zig") });

    const multi = b.addModule("multi", .{ .root_source_file = b.path("src/multi.zig") });
    multi.addImport("widget", widget);
}
