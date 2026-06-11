//! Parse a ZON file and emit its contents as JSON on stdout.

const std = @import("std");
const Zoir = std.zig.Zoir;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(allocator);
    if (args.len != 2) fatal("usage: zon2json <file.zon>", .{});

    const source = try std.Io.Dir.cwd().readFileAllocOptions(io, args[1], allocator, .unlimited, .of(u8), 0);

    const ast = try std.zig.Ast.parse(allocator, source, .zon);
    const zoir = try std.zig.ZonGen.generate(allocator, ast, .{});
    if (zoir.compile_errors.len != 0) fatal("'{s}' is not valid ZON", .{args[1]});

    var stdout_buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(io, &stdout_buffer);
    const writer = &stdout.interface;

    var json: std.json.Stringify = .{ .writer = writer };
    try writeNode(&json, zoir, .root);
    try writer.writeByte('\n');
    try writer.flush();
}

fn writeNode(json: *std.json.Stringify, zoir: Zoir, index: Zoir.Node.Index) !void {
    switch (index.get(zoir)) {
        .true => try json.write(true),
        .false => try json.write(false),
        .null, .pos_inf, .neg_inf, .nan => try json.write(null),
        .int_literal => |int| switch (int) {
            .small => |small| try json.write(small),
            .big => |big| try json.print("{f}", .{big}),
        },
        .float_literal => |float| try json.write(float),
        .char_literal => |char| try json.write(char),
        .enum_literal => |name| try json.write(name.get(zoir)),
        .string_literal => |string| try json.write(string),
        .empty_literal => {
            try json.beginObject();
            try json.endObject();
        },
        .array_literal => |elements| {
            try json.beginArray();
            for (0..elements.len) |i| try writeNode(json, zoir, elements.at(@intCast(i)));
            try json.endArray();
        },
        .struct_literal => |fields| {
            try json.beginObject();
            for (fields.names, 0..) |name, i| {
                try json.objectField(name.get(zoir));
                try writeNode(json, zoir, fields.vals.at(@intCast(i)));
            }
            try json.endObject();
        },
    }
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print("zon2json: " ++ format ++ "\n", args);
    std.process.exit(1);
}
