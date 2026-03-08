const std = @import("std");
const c = @cImport({
    @cInclude("zero.h");
});

pub fn c_call() !void {
    const len: u8 = 64;
    var buf: [64]u8 = undefined;
    c.zero(&buf, len);
}

pub fn main() !void {
    try c_call();
}

test "call c library zero()\n" {
    try c_call();
}
