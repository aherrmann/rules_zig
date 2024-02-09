const std = @import("std");
const runfiles = @import("runfiles");
const bazel_builtin = @import("bazel_builtin");

pub fn readData(allocator: std.mem.Allocator) ![]const u8 {
    var r = try runfiles.Runfiles.create(.{ .allocator = allocator });
    defer r.deinit(allocator);

    const rpath = "runfiles_library_transitive_dependency/data.txt";

    const file_path = try r.rlocation(allocator, rpath, bazel_builtin.current_repository) orelse
        return error.RLocationNotFound;
    defer allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 4096);
}

test "read data file in dependency module" {
    const content = try readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello from transitive dependency!\n", content);
}
