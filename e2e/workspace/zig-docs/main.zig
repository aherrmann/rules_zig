//!zig-autodoc-guide: guide.md

const builtin = @import("builtin");
const std = @import("std");
pub const hello_world = @import("hello_world");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;
pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() void {
    std.fs.File.stdout().writeAll(hello_world.msg ++ "\n") catch unreachable;
}

fn main_016(init: std.process.Init) void {
    std.Io.File.writeStreamingAll(.stdout(), init.io, hello_world.msg ++ "\n") catch unreachable;
}

test hello_world {
    // Hello World message.
    try std.testing.expectEqualStrings("Hello World!", hello_world.msg);
}
