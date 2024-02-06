const std = @import("std");
const log = std.log.scoped(.runfiles);

pub const runfiles_manifest_var_name = "RUNFILES_MANIFEST_FILE";
pub const runfiles_directory_var_name = "RUNFILES_DIR";
pub const runfiles_manifest_suffix = ".runfiles_manifest";
pub const runfiles_directory_suffix = ".runfiles";

fn getEnvVar(allocator: std.mem.Allocator, key: []const u8) !?[]const u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}

pub fn discoverRunfiles(allocator: std.mem.Allocator) ![]const u8 {
    if (try getEnvVar(allocator, runfiles_directory_var_name)) |value| {
        return value;
    } else {
        var iter = try std.process.argsWithAllocator(allocator);
        defer iter.deinit();

        const argv0 = iter.next() orelse
            return error.Argv0Unavailable;

        const check_path = try std.fmt.allocPrint(
            allocator,
            "{s}" ++ runfiles_directory_suffix,
            .{argv0},
        );
        errdefer allocator.free(check_path);

        var dir = std.fs.cwd().openDir(check_path, .{}) catch
            return error.RunfilesNotFound;
        dir.close();

        return check_path;
    }
}
