const local_zig = @import("local_zig");

pub fn local() u8 {
    return local_zig.local();
}
