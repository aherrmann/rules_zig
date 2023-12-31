const std = @import("std");
const builtin = @import("builtin");

extern const rlocationpath: [*:0]const u8;
extern const target: [*:0]const u8;
extern const zig_target: [*:0]const u8;

test "RLOCATIONPATH is set" {
    try std.testing.expectStringEndsWith(
        std.mem.sliceTo(rlocationpath, 0),
        "location-expansion/data.txt",
    );
}

test "TARGET is set" {
    try std.testing.expectEqualStrings(
        "//location-expansion:test",
        std.mem.sliceTo(target, 0),
    );
}

test "ZIG_TARGET is set" {
    const actual_target = try builtin.target.linuxTriple(std.testing.allocator);
    defer std.testing.allocator.free(actual_target);
    try std.testing.expectEqualStrings(
        actual_target,
        std.mem.sliceTo(zig_target, 0),
    );
}
