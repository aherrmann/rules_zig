const hello = @import("data/hello.zig");
const world = @import("data/world.zig");

pub const hello_world = hello.data ++ " " ++ world.data ++ "\n";
