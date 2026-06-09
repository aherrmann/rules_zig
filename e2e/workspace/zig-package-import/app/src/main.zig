const std = @import("std");
const clap = @import("clap");
const greet = @import("greet");

pub fn main(init: std.process.Init) !void {
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &greet.params, clap.parsers.default, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.helpToFile(init.io, .stderr(), clap.Help, &greet.params, .{});

    const message = try greet.greeting(init.gpa, res);
    defer init.gpa.free(message);
    std.debug.print("{s}\n", .{message});
}
