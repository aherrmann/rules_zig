const builtin = @import("builtin");
const std = @import("std");

export fn sayHello() void {
    const stdout = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15)
        std.fs.File.stdout()
    else
        std.io.getStdOut();
    stdout.writeAll(
        "Hello World!\n",
    ) catch unreachable;
}
