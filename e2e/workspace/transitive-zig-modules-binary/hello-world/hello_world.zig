const std = @import("std");
const builtin = @import("builtin");
const data = @import("data");
const io = @import("io");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;
const Io = if (is_zig_0_16_or_later) std.Io else void;

pub fn sayHello() void {
    io.print(data.hello_world);
}

pub fn sayHelloWithIo(process_io: Io) void {
    io.printWithIo(process_io, data.hello_world);
}
