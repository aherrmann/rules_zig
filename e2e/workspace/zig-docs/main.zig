//!zig-autodoc-guide: guide.md

// NOTE: zig-autodoc-guide not supported as of Zig 0.14+,
// see https://ziggit.dev/t/zig-autodoc-render-markdown-files/10314/2

const builtin = @import("builtin");
const std = @import("std");
pub const hello_world = @import("hello_world");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

/// Prints "Hello World!".
pub const say_hello_world = if (is_zig_0_16_or_later) say_hello_world_016 else say_hello_world_pre_016;

fn say_hello_world_016(io: anytype) !void {
    std.Io.File.writeStreamingAll(.stdout(), io, hello_world.msg ++ "\n") catch unreachable;
}

fn say_hello_world_pre_016() !void {
    std.fs.File.stdout().writeAll(hello_world.msg ++ "\n") catch unreachable;
}

/// Program entry-point.
/// Prints "Hello World!".
pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() void {
    say_hello_world_pre_016() catch unreachable;
}

fn main_016(init: std.process.Init) void {
    say_hello_world(init.io) catch unreachable;
}

test hello_world {
    // Hello World message.
    try std.testing.expectEqualStrings("Hello World!", hello_world.msg);
}
