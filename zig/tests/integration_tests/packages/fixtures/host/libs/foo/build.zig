pub fn build(b: *@import("std").Build) void {
    const leaf = b.dependency("leaf", .{});
    const foo = b.addModule("foo", .{ .root_source_file = b.path("src/foo.zig") });
    foo.addImport("leaf", leaf.module("leaf"));
}
