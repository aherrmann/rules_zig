const add = @import("add");
const std = @import("std");

pub fn main() !void {
    const a = 5;
    const b = 10;
    const result = add.add(a, b);
    std.debug.print("Result: {}\n", .{result});
}
