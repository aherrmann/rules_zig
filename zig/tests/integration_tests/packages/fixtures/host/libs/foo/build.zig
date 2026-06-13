pub fn build(b: *@import("std").Build) void {
    _ = b.addModule("foo", .{ .root_source_file = b.path("src/foo.zig") });
}
