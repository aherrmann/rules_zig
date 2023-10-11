const std = @import("std");

export fn sayHello() void {
    std.io.getStdOut().writeAll(
        "Hello World!\n",
    ) catch unreachable;
}
