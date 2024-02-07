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
}) !Location {
    if (options.manifest) |value|
        return .{ .manifest = try options.allocator.dupe(u8, value) };

    if (options.directory) |value|
        return .{ .directory = try options.allocator.dupe(u8, value) };

    if (try getEnvVar(options.allocator, runfiles_manifest_var_name)) |value|
        return .{ .manifest = value };

    if (try getEnvVar(options.allocator, runfiles_directory_var_name)) |value|
        return .{ .directory = value };

    var iter = try std.process.argsWithAllocator(options.allocator);
    defer iter.deinit();
    const argv0 = options.argv0 orelse iter.next() orelse
        return error.Argv0Unavailable;

    var buffer = std.ArrayList(u8).init(options.allocator);
    defer buffer.deinit();

    buffer.clearRetainingCapacity();
    try buffer.writer().print("{s}{s}", .{ argv0, runfiles_manifest_suffix });
    if (isReadableFile(buffer.items))
        return .{ .manifest = try buffer.toOwnedSlice() };

    buffer.clearRetainingCapacity();
    try buffer.writer().print("{s}.exe{s}", .{ argv0, runfiles_manifest_suffix });
    if (isReadableFile(buffer.items))
        return .{ .manifest = try buffer.toOwnedSlice() };

    buffer.clearRetainingCapacity();
    try buffer.writer().print("{s}{s}", .{ argv0, runfiles_directory_suffix });
    if (isOpenableDir(buffer.items))
        return .{ .directory = try buffer.toOwnedSlice() };

    buffer.clearRetainingCapacity();
    try buffer.writer().print("{s}.exe{s}", .{ argv0, runfiles_directory_suffix });
    if (isOpenableDir(buffer.items))
        return .{ .directory = try buffer.toOwnedSlice() };

    return error.RunfilesNotFound;
}

fn getEnvVar(allocator: std.mem.Allocator, key: []const u8) !?[]const u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}

fn isReadableFile(file_path: []const u8) bool {
    var file = std.fs.cwd().openFile(file_path, .{}) catch return false;
    file.close();
    return true;
}

fn isOpenableDir(dir_path: []const u8) bool {
    var dir = std.fs.cwd().openDir(dir_path, .{}) catch return false;
    dir.close();
    return true;
}
