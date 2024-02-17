const hello = @import("hello");
const world = @import("world");

pub const hello_world = hello.data ++ " " ++ world.data ++ "\n";
