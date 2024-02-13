// TODO[AH] The `../` prefix is necessary for Zig to find the guide.
//   That may be a bug in Zig autodoc, looking at strace it attempts to open
//   `zig-docs/guide.md` from within the `zig-docs` directory.
//!zig-autodoc-guide: ../guide.md

const std = @import("std");
const hello_world = @import("hello_world");

/// Prints "Hello World!".
pub fn say_hello_world() !void {
    try std.io.getStdOut().writeAll(
        hello_world.msg ++ "\n",
    );
}

/// Program entry-point.
/// Prints "Hello World!".
pub fn main() void {
    say_hello_world() catch unreachable;
}
