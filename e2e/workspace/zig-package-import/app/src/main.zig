const std = @import("std");
const clap = @import("clap");
const greet = @import("greet");
const cbor = @import("cbor");
const gex = @import("ezi_gex");

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

    // CBOR-encode the greeting using the git+https `cbor` dependency.
    var cbor_buf: [256]u8 = undefined;
    const encoded = cbor.fmt(&cbor_buf, message);

    // Match a pattern with the multi-module `ezi_gex` regex engine.
    var gex_diag: gex.Diagnostic = .{};
    var re = try gex.compileRuntime(init.gpa, "(?<user>\\w+)@(?<host>\\w+)", &gex_diag, .{});
    defer re.deinit();
    var scratch = try @TypeOf(re).Scratch.init(init.gpa, &re.program);
    defer scratch.deinit(init.gpa);
    const haystack = "contact: bob@example";
    const match = if (re.find(&scratch, haystack)) |m| m.slice(haystack) else "(none)";

    var stdout_buf: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buf);
    const stdout = &stdout_writer.interface;
    try stdout.print("{s}\n", .{message});
    try stdout.print("cbor: {d} bytes\n", .{encoded.len});
    try stdout.print("regex match: {s}\n", .{match});
    try stdout.flush();
}
