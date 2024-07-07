//! Implements the runfiles strategy and discovery as defined in the following design document:
//! https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub

const std = @import("std");
const builtin = @import("builtin");
const log = std.log.scoped(.runfiles);

pub const runfiles_manifest_var_name = "RUNFILES_MANIFEST_FILE";
pub const runfiles_directory_var_name = "RUNFILES_DIR";
pub const runfiles_manifest_suffix = ".runfiles_manifest";
pub const runfiles_directory_suffix = ".runfiles";
pub const repo_mapping_file_name = "_repo_mapping";

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

    pub fn deinit(self: *Location, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .manifest => |value| allocator.free(value),
            .directory => |value| allocator.free(value),
        }
    }
};

pub const DiscoverOptions = struct {
    /// Used during runfiles discovery.
    allocator: std.mem.Allocator,
    /// User override for the `RUNFILES_MANIFEST_FILE` variable.
    manifest: ?[]const u8 = null,
    /// User override for the `RUNFILES_DIRECTORY` variable.
    directory: ?[]const u8 = null,
    /// User override for `argv[0]`.
    argv0: ?[]const u8 = null,
};

pub const DiscoverError = if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 11)
    error{
        OutOfMemory,
        InvalidCmdLine,
        InvalidUtf8,
        MissingArg0,
    }
else
    error{
        OutOfMemory,
        InvalidCmdLine,
        InvalidWtf8,
        MissingArg0,
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
pub fn discoverRunfiles(options: DiscoverOptions) DiscoverError!?Location {
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
        return error.MissingArg0;

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

    return null;
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

const testing = struct {
    const c = @cImport({
        @cInclude("stdlib.h");
    });

    pub fn setenv(name: []const u8, value: []const u8) !void {
        const nameZ = try std.testing.allocator.dupeZ(u8, name);
        defer std.testing.allocator.free(nameZ);
        const valueZ = try std.testing.allocator.dupeZ(u8, value);
        defer std.testing.allocator.free(valueZ);
        if (builtin.os.tag == .windows) {
            if (testing.c._putenv_s(nameZ, valueZ) != 0)
                return error.SetEnvFailed;
        } else {
            if (testing.c.setenv(nameZ, valueZ, 1) != 0)
                return error.SetEnvFailed;
        }
    }

    pub fn unsetenv(name: []const u8) !void {
        const nameZ = try std.testing.allocator.dupeZ(u8, name);
        defer std.testing.allocator.free(nameZ);
        if (builtin.os.tag == .windows) {
            if (testing.c._putenv_s(nameZ, "") != 0)
                return error.UnsetEnvFailed;
        } else {
            if (testing.c.unsetenv(nameZ) != 0)
                return error.UnsetEnvFailed;
        }
    }
};

test "discover user specified manifest" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor < 13) {
        try tmp.dir.writeFile("test.runfiles_manifest", "");
    } else {
        try tmp.dir.writeFile(.{
            .sub_path = "test.runfiles_manifest",
            .data = "",
        });
    }

    const manifest_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles_manifest");
    defer std.testing.allocator.free(manifest_path);

    try testing.setenv(runfiles_manifest_var_name, "MANIFEST_DOES_NOT_EXIST");
    try testing.setenv(runfiles_directory_var_name, "DIRECTORY_DOES_NOT_EXIST");

    var location = try discoverRunfiles(.{
        .allocator = std.testing.allocator,
        .manifest = manifest_path,
    }) orelse
        return error.TestRunfilesNotFound;
    defer location.deinit(std.testing.allocator);

    try std.testing.expectEqual(Strategy.manifest, @as(Strategy, location));
    try std.testing.expectEqualStrings(manifest_path, location.manifest);
}

test "discover environment specified manifest" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor < 13) {
        try tmp.dir.writeFile("test.runfiles_manifest", "");
    } else {
        try tmp.dir.writeFile(.{
            .sub_path = "test.runfiles_manifest",
            .data = "",
        });
    }

    const manifest_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles_manifest");
    defer std.testing.allocator.free(manifest_path);

    try testing.setenv(runfiles_manifest_var_name, manifest_path);
    try testing.unsetenv(runfiles_directory_var_name);

    var location = try discoverRunfiles(.{
        .allocator = std.testing.allocator,
    }) orelse
        return error.TestRunfilesNotFound;
    defer location.deinit(std.testing.allocator);

    try std.testing.expectEqual(Strategy.manifest, @as(Strategy, location));
    try std.testing.expectEqualStrings(manifest_path, location.manifest);
}

test "discover user specified directory" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.makeDir("test.runfiles");

    const directory_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles");
    defer std.testing.allocator.free(directory_path);

    try testing.setenv(runfiles_manifest_var_name, "MANIFEST_DOES_NOT_EXIST");
    try testing.setenv(runfiles_directory_var_name, "DIRECTORY_DOES_NOT_EXIST");

    var location = try discoverRunfiles(.{ .allocator = std.testing.allocator, .directory = directory_path }) orelse
        return error.TestRunfilesNotFound;
    defer location.deinit(std.testing.allocator);

    try std.testing.expectEqual(Strategy.directory, @as(Strategy, location));
    try std.testing.expectEqualStrings(directory_path, location.directory);
}

test "discover environment specified directory" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.makeDir("test.runfiles");

    const directory_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles");
    defer std.testing.allocator.free(directory_path);

    try testing.unsetenv(runfiles_manifest_var_name);
    try testing.setenv(runfiles_directory_var_name, directory_path);

    var location = try discoverRunfiles(.{
        .allocator = std.testing.allocator,
    }) orelse
        return error.TestRunfilesNotFound;
    defer location.deinit(std.testing.allocator);

    try std.testing.expectEqual(Strategy.directory, @as(Strategy, location));
    try std.testing.expectEqualStrings(directory_path, location.directory);
}

test "discover user specified argv0 manifest" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor < 13) {
        try tmp.dir.writeFile("test.runfiles_manifest", "");
    } else {
        try tmp.dir.writeFile(.{
            .sub_path = "test.runfiles_manifest",
            .data = "",
        });
    }

    const manifest_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles_manifest");
    defer std.testing.allocator.free(manifest_path);

    try testing.unsetenv(runfiles_manifest_var_name);
    try testing.unsetenv(runfiles_directory_var_name);

    const argv0 = manifest_path[0 .. manifest_path.len - ".runfiles_manifest".len];

    var location = try discoverRunfiles(.{
        .allocator = std.testing.allocator,
        .argv0 = argv0,
    }) orelse
        return error.TestRunfilesNotFound;
    defer location.deinit(std.testing.allocator);

    try std.testing.expectEqual(Strategy.manifest, @as(Strategy, location));
    try std.testing.expectEqualStrings(manifest_path, location.manifest);
}

test "discover user specified argv0 .exe manifest" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor < 13) {
        try tmp.dir.writeFile("test.exe.runfiles_manifest", "");
    } else {
        try tmp.dir.writeFile(.{
            .sub_path = "test.exe.runfiles_manifest",
            .data = "",
        });
    }

    const manifest_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.exe.runfiles_manifest");
    defer std.testing.allocator.free(manifest_path);

    try testing.unsetenv(runfiles_manifest_var_name);
    try testing.unsetenv(runfiles_directory_var_name);

    const argv0 = manifest_path[0 .. manifest_path.len - ".exe.runfiles_manifest".len];

    var location = try discoverRunfiles(.{
        .allocator = std.testing.allocator,
        .argv0 = argv0,
    }) orelse
        return error.TestRunfilesNotFound;
    defer location.deinit(std.testing.allocator);

    try std.testing.expectEqual(Strategy.manifest, @as(Strategy, location));
    try std.testing.expectEqualStrings(manifest_path, location.manifest);
}

test "discover user specified argv0 directory" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.makeDir("test.runfiles");

    const directory_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles");
    defer std.testing.allocator.free(directory_path);

    try testing.unsetenv(runfiles_manifest_var_name);
    try testing.unsetenv(runfiles_directory_var_name);

    const argv0 = directory_path[0 .. directory_path.len - ".runfiles".len];

    var location = try discoverRunfiles(.{
        .allocator = std.testing.allocator,
        .argv0 = argv0,
    }) orelse
        return error.TestRunfilesNotFound;
    defer location.deinit(std.testing.allocator);

    try std.testing.expectEqual(Strategy.directory, @as(Strategy, location));
    try std.testing.expectEqualStrings(directory_path, location.directory);
}

test "discover user specified argv0 .exe directory" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.makeDir("test.exe.runfiles");

    const directory_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.exe.runfiles");
    defer std.testing.allocator.free(directory_path);

    try testing.unsetenv(runfiles_manifest_var_name);
    try testing.unsetenv(runfiles_directory_var_name);

    const argv0 = directory_path[0 .. directory_path.len - ".exe.runfiles".len];

    var location = try discoverRunfiles(.{
        .allocator = std.testing.allocator,
        .argv0 = argv0,
    }) orelse
        return error.TestRunfilesNotFound;
    defer location.deinit(std.testing.allocator);

    try std.testing.expectEqual(Strategy.directory, @as(Strategy, location));
    try std.testing.expectEqualStrings(directory_path, location.directory);
}

test "discover not found" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const tmp_path = try tmp.dir.realpathAlloc(std.testing.allocator, ".");
    defer std.testing.allocator.free(tmp_path);

    try testing.unsetenv(runfiles_manifest_var_name);
    try testing.unsetenv(runfiles_directory_var_name);

    const argv0 = try std.fmt.allocPrint(std.testing.allocator, "{s}/does-not-exist", .{tmp_path});
    defer std.testing.allocator.free(argv0);

    const result = try discoverRunfiles(.{
        .allocator = std.testing.allocator,
        .argv0 = argv0,
    });

    try std.testing.expectEqual(@as(?Location, null), result);
}

test "discover priority" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor < 13) {
        try tmp.dir.writeFile("test.runfiles_manifest", "");
    } else {
        try tmp.dir.writeFile(.{
            .sub_path = "test.runfiles_manifest",
            .data = "",
        });
    }
    try tmp.dir.makeDir("test.runfiles");

    const manifest_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles_manifest");
    defer std.testing.allocator.free(manifest_path);
    const directory_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles");
    defer std.testing.allocator.free(directory_path);

    const argv0 = manifest_path[0 .. manifest_path.len - ".runfiles_manifest".len];

    {
        // user specified manifest first.

        try testing.setenv(runfiles_manifest_var_name, manifest_path);
        try testing.setenv(runfiles_directory_var_name, directory_path);

        var location = try discoverRunfiles(.{
            .allocator = std.testing.allocator,
            .manifest = manifest_path,
            .directory = directory_path,
            .argv0 = argv0,
        }) orelse
            return error.TestRunfilesNotFound;
        defer location.deinit(std.testing.allocator);

        try std.testing.expectEqual(Strategy.manifest, @as(Strategy, location));
        try std.testing.expectEqualStrings(manifest_path, location.manifest);
    }

    {
        // user specified directory next.

        try testing.setenv(runfiles_manifest_var_name, manifest_path);
        try testing.setenv(runfiles_directory_var_name, directory_path);

        var location = try discoverRunfiles(.{
            .allocator = std.testing.allocator,
            .directory = directory_path,
            .argv0 = argv0,
        }) orelse
            return error.TestRunfilesNotFound;
        defer location.deinit(std.testing.allocator);

        try std.testing.expectEqual(Strategy.directory, @as(Strategy, location));
        try std.testing.expectEqualStrings(directory_path, location.directory);
    }

    {
        // environment specified manifest next.

        try testing.setenv(runfiles_manifest_var_name, manifest_path);
        try testing.setenv(runfiles_directory_var_name, directory_path);

        var location = try discoverRunfiles(.{
            .allocator = std.testing.allocator,
            .argv0 = argv0,
        }) orelse
            return error.TestRunfilesNotFound;
        defer location.deinit(std.testing.allocator);

        try std.testing.expectEqual(Strategy.manifest, @as(Strategy, location));
        try std.testing.expectEqualStrings(manifest_path, location.manifest);
    }

    {
        // environment specified directory next.

        try testing.unsetenv(runfiles_manifest_var_name);
        try testing.setenv(runfiles_directory_var_name, directory_path);

        var location = try discoverRunfiles(.{
            .allocator = std.testing.allocator,
            .argv0 = argv0,
        }) orelse
            return error.TestRunfilesNotFound;
        defer location.deinit(std.testing.allocator);

        try std.testing.expectEqual(Strategy.directory, @as(Strategy, location));
        try std.testing.expectEqualStrings(directory_path, location.directory);
    }

    {
        // argv0 specified manifest next.

        try testing.unsetenv(runfiles_manifest_var_name);
        try testing.unsetenv(runfiles_directory_var_name);

        var location = try discoverRunfiles(.{
            .allocator = std.testing.allocator,
            .argv0 = argv0,
        }) orelse
            return error.TestRunfilesNotFound;
        defer location.deinit(std.testing.allocator);

        try std.testing.expectEqual(Strategy.manifest, @as(Strategy, location));
        try std.testing.expectEqualStrings(manifest_path, location.manifest);
    }

    try tmp.dir.deleteFile("test.runfiles_manifest");

    {
        // argv0 specified directory next.

        try testing.unsetenv(runfiles_manifest_var_name);
        try testing.unsetenv(runfiles_directory_var_name);

        var location = try discoverRunfiles(.{
            .allocator = std.testing.allocator,
            .argv0 = argv0,
        }) orelse
            return error.TestRunfilesNotFound;
        defer location.deinit(std.testing.allocator);

        try std.testing.expectEqual(Strategy.directory, @as(Strategy, location));
        try std.testing.expectEqualStrings(directory_path, location.directory);
    }

    try tmp.dir.deleteDir("test.runfiles");

    {
        // finally runfiles not found.

        try testing.unsetenv(runfiles_manifest_var_name);
        try testing.unsetenv(runfiles_directory_var_name);

        const result = try discoverRunfiles(.{
            .allocator = std.testing.allocator,
            .argv0 = argv0,
        });

        try std.testing.expectEqual(@as(?Location, null), result);
    }
}
