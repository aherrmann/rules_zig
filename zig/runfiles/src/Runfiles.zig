const std = @import("std");

const Self = @This();

directory: []const u8,

pub fn create(allocator: std.mem.Allocator) !Self {
    var iter = try std.process.argsWithAllocator(allocator);
    defer iter.deinit();

    const argv0 = iter.next() orelse
        return error.Argv0Unavailable;

    const check_path = try std.fmt.allocPrint(
        allocator,
        "{s}.runfiles",
        .{argv0},
    );
    defer allocator.free(check_path);

    var dir = std.fs.cwd().openDir(check_path, .{}) catch
        return error.RunfilesNotFound;
    dir.close();

    const runfiles_path = try std.fs.cwd().realpathAlloc(allocator, check_path);

    return .{
        .directory = runfiles_path,
    };
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.free(self.directory);
}
