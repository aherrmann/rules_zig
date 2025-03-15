const std = @import("std");

extern fn add(a: i32, b: i32) i32;

export fn mul(a: i32, b: i32) i32 {
    var i: i32 = 0;
    var result: i32 = 0;
    while (i < @abs(a)) : (i += 1) {
        result = add(result, b);
    }
    return if (a < 0) -result else result;
}
