const std = @import("std");
const log = std.log.scoped(.runfiles);

fn getEnvVar(allocator: std.mem.Allocator, key: []const u8) !?[]const u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}

pub fn discoverRunfiles(allocator: std.mem.Allocator) ![]const u8 {
    if (try getEnvVar(allocator, "RUNFILES_DIR")) |value| {
        defer allocator.free(value);
        return try std.fs.cwd().realpathAlloc(allocator, value);
    } else {
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

        return try std.fs.cwd().realpathAlloc(allocator, check_path);
    }
}
