//! Print the directory prefix of the shallowest `build.zig.zon` in a Zig
//! package archive (a gzip-compressed tarball), for use as an extraction
//! `strip_prefix`.
//!
//! Usage: package_prefix <archive.tar.gz>

const std = @import("std");
const flate = std.compress.flate;
const tar = std.tar;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(allocator);
    if (args.len != 2) fatal("usage: package_prefix <archive.tar.gz>", .{});

    var file = try std.Io.Dir.cwd().openFile(io, args[1], .{});
    defer file.close(io);

    var read_buffer: [64 * 1024]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);

    var window: [flate.max_window_len]u8 = undefined;
    var decompress: flate.Decompress = .init(&file_reader.interface, .gzip, &window);

    var name_buffer: [std.fs.max_path_bytes]u8 = undefined;
    var link_name_buffer: [std.fs.max_path_bytes]u8 = undefined;
    var iterator: tar.Iterator = .init(&decompress.reader, .{
        .file_name_buffer = &name_buffer,
        .link_name_buffer = &link_name_buffer,
    });

    var prefix: ?[]const u8 = null;
    while (try iterator.next()) |entry| {
        if (entry.kind == .directory) continue;
        if (!std.mem.eql(u8, std.fs.path.basename(entry.name), "build.zig.zon")) continue;

        const dir = std.fs.path.dirname(entry.name) orelse "";
        if (prefix == null or dir.len < prefix.?.len) {
            prefix = try allocator.dupe(u8, dir);
        }
    }

    const result = prefix orelse fatal("no `build.zig.zon` found in '{s}'", .{args[1]});

    var stdout_buffer: [std.fs.max_path_bytes]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(io, &stdout_buffer);
    try stdout.interface.writeAll(result);
    try stdout.interface.writeByte('\n');
    try stdout.interface.flush();
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print("package_prefix: " ++ format ++ "\n", args);
    std.process.exit(1);
}
