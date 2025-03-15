extern fn one() i32;

export fn two() i32 {
    return one() + one();
}
