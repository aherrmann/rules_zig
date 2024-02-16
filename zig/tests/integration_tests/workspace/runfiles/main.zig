const std = @import("std");
const runfiles = @import("runfiles");
const bazel_builtin = @import("bazel_builtin");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var r = try runfiles.Runfiles.create(.{ .allocator = allocator }) orelse
        return error.RunfilesNotFound;
    defer r.deinit(allocator);

    const rpath = "__main__/runfiles/data.txt";

    const file_path = try r.rlocationAlloc(allocator, rpath, bazel_builtin.current_repository) orelse {
        std.log.err("Runfiles location '{s}' not found", .{rpath});
        return error.RLocationNotFound;
    };
    defer allocator.free(file_path);

    const file = std.fs.cwd().openFile(file_path, .{}) catch |e| {
        std.log.err("Failed to open file '{s}': {}", .{ file_path, e });
        return e;
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(content);

    try std.io.getStdOut().writer().print("data: {s}", .{content});
}
