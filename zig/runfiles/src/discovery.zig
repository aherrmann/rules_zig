//! Implements the runfiles strategy and discovery as defined in the following design document:
//! https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub

const std = @import("std");
const log = std.log.scoped(.runfiles);

pub const runfiles_manifest_var_name = "RUNFILES_MANIFEST_FILE";
pub const runfiles_directory_var_name = "RUNFILES_DIR";
pub const runfiles_manifest_suffix = ".runfiles_manifest";
pub const runfiles_directory_suffix = ".runfiles";

/// * Manifest-based: reads the runfiles manifest file to look up runfiles.
/// * Directory-based: appends the runfile's path to the runfiles root.
///   The client is responsible for checking that the resulting path exists.
pub const Strategy = enum {
    manifest,
    directory,
};

/// The path to a runfiles manifest file or a runfiles directory.
pub const Location = union(Strategy) {
    manifest: []const u8,
    directory: []const u8,
};

/// The unified runfiles discovery strategy is to:
/// * check if `RUNFILES_MANIFEST_FILE` or `RUNFILES_DIR` envvars are set, and
///   again initialize a `Runfiles` object accordingly; otherwise
/// * check if the `argv[0] + ".runfiles_manifest"` file or the
///   `argv[0] + ".runfiles"` directory exists (keeping in mind that argv[0]
///   may not include the `".exe"` suffix on Windows), and if so, initialize a
///   manifest- or directory-based `Runfiles` object; otherwise
/// * assume the binary has no runfiles.
///
/// The caller has to free the path contained in the returned location.
pub fn discoverRunfiles(options: struct {
    /// Used to allocate intermediate data and the final location.
    allocator: std.mem.Allocator,
    /// User override for the `RUNFILES_MANIFEST_FILE` variable.
    manifest: ?[]const u8 = null,
    /// User override for the `RUNFILES_DIRECTORY` variable.
    directory: ?[]const u8 = null,
    /// User override for `argv[0]`.
    argv0: ?[]const u8 = null,
}) ![]const u8 {
    if (try getEnvVar(options.allocator, runfiles_directory_var_name)) |value| {
        return value;
    } else {
        var iter = try std.process.argsWithAllocator(options.allocator);
        defer iter.deinit();

        const argv0 = iter.next() orelse
            return error.Argv0Unavailable;

        const check_path = try std.fmt.allocPrint(
            options.allocator,
            "{s}" ++ runfiles_directory_suffix,
            .{argv0},
        );
        errdefer options.allocator.free(check_path);

        var dir = std.fs.cwd().openDir(check_path, .{}) catch
            return error.RunfilesNotFound;
        dir.close();

        return check_path;
    }
}

fn getEnvVar(allocator: std.mem.Allocator, key: []const u8) !?[]const u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}
