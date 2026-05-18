const generated = @import("generated");
const mid = @import("mid");
const named = @import("custom/named");
const nested = @import("nested/module");

pub fn value() i32 {
    return generated.generated_value + mid.value() + @as(i32, @intFromBool(named.enabled)) + nested.value;
}

pub fn main() void {
    _ = value();
}
