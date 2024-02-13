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
