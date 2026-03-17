const c = @cImport({
    @cInclude("hello.h");
});

pub fn main() !void {
    c.hello();
}
