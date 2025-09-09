const std = @import("std");
const module = @import("module");
const c = @import("c");

pub fn main() u8 {
    std.debug.print("From Global translate-c={d}, From local translate-c={d}!\n", .{module.corentin_zig_module(), c.corentin()});
    return 0;
}
