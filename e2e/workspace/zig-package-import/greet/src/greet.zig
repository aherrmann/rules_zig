const std = @import("std");
const clap = @import("clap");

// contrived example to introduce a transitive clap dependency
pub const params = clap.parseParamsComptime(
    \\-h, --help        Display this help and exit.
    \\-n, --name <str>  Name to greet (defaults to "world").
    \\
);

pub fn greeting(allocator: std.mem.Allocator, res: anytype) ![]u8 {
    const name = res.args.name orelse "world";
    return std.fmt.allocPrint(allocator, "Hello {s}!", .{name});
}
