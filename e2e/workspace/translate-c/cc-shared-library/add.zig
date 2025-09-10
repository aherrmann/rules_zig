const c_add_zig = @import("c-add_zig");

pub fn add(a: i32, b: i32) i32 {
    return c_add_zig.add(a, b);
}
