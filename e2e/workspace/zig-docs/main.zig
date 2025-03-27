//!zig-autodoc-guide: guide.md

const std = @import("std");

/// Prints "Hello World!".
pub fn say_hello_world() !void {
    try std.io.getStdOut().writeAll(
        "Hello World!\n",
    );
}

/// Program entry-point.
/// Prints "Hello World!".
pub fn main() void {
    say_hello_world() catch unreachable;
}

test "hello_world" {
    // Hello World message.
    try std.testing.expectEqualStrings("Hello World!", "Hello World!");
}
