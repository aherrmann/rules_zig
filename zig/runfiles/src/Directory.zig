//! Implements the directory based runfiles strategy as defined in the
//! [runfiles design][runfiles-design].
//!
//! [runfiles-design]: https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub

const std = @import("std");
const builtin = @import("builtin");
const testutil = @import("testutil.zig");

const RPath = @import("RPath.zig");

const Directory = @This();

path: []const u8,

pub const InitError = std.mem.Allocator.Error || (if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 11)
    std.os.OpenError || std.os.RealPathError
else if (builtin.zig_version.major == 0 and builtin.zig_version.minor <= 15)
    std.posix.OpenError || std.posix.RealPathError
else
    std.Io.Dir.OpenError || std.Io.Dir.RealPathFileAllocError);

pub const init = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16)
    init_016
else
    init_pre_016;

pub fn init_pre_016(allocator: std.mem.Allocator, path: []const u8) InitError!Directory {
    const absolute = try std.fs.cwd().realpathAlloc(allocator, path);
    errdefer allocator.free(absolute);
    // TODO[AH] Implement OS specific normalization, e.g. Windows lower-case.
    return .{ .path = absolute };
}

pub fn init_016(allocator: std.mem.Allocator, io: std.Io, path: []const u8) InitError!Directory {
    const absolute = try testutil.ownNoSentinel(allocator, try std.Io.Dir.cwd().realPathFileAlloc(io, path, allocator));
    errdefer allocator.free(absolute);
    // TODO[AH] Implement OS specific normalization, e.g. Windows lower-case.
    return .{ .path = absolute };
}

pub fn deinit(self: *Directory, allocator: std.mem.Allocator) void {
    allocator.free(self.path);
}

pub fn rlocationUnmapped(
    self: *const Directory,
    rpath: RPath,
    out_buffer: []u8,
) error{NoSpaceLeft}![]const u8 {
    var writer = std.Io.Writer.fixed(out_buffer);
    writer.print("{s}", .{self.path}) catch return error.NoSpaceLeft;
    if (rpath.repo.len > 0)
        writer.print("/{s}", .{rpath.repo}) catch return error.NoSpaceLeft;
    if (rpath.path.len > 0)
        writer.print("/{s}", .{rpath.path}) catch return error.NoSpaceLeft;
    return writer.buffered();
}

pub fn rlocationUnmappedAlloc(
    self: *const Directory,
    allocator: std.mem.Allocator,
    rpath: RPath,
) error{OutOfMemory}![]const u8 {
    // TODO[AH] Implement OS specific normalization, e.g. Windows lower-case.
    return try std.fs.path.join(allocator, &[_][]const u8{
        self.path,
        rpath.repo,
        rpath.path,
    });
}

test "Directory init and unmapped lookup" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try testutil.tmpMakePath(tmp.dir, "test.runfiles/my_workspace/some/package");
    try testutil.tmpWriteFile(tmp.dir, "test.runfiles/_repo_mapping", "_repo_mapping");
    try testutil.tmpWriteFile(tmp.dir, "test.runfiles/my_workspace/some/package/some_file", "some_file");

    const cwd_path_absolute = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16)
        try std.process.currentPathAlloc(std.Io.Threaded.global_single_threaded.io(), std.testing.allocator)
    else
        try std.fs.cwd().realpathAlloc(std.testing.allocator, ".");
    defer std.testing.allocator.free(cwd_path_absolute);
    const runfiles_path_absolute = try testutil.tmpRealpathAlloc(tmp.dir, std.testing.allocator, "test.runfiles");
    defer std.testing.allocator.free(runfiles_path_absolute);
    const runfiles_path = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16)
        try std.fs.path.relative(std.testing.allocator, ".", null, cwd_path_absolute, runfiles_path_absolute)
    else
        try std.fs.path.relative(std.testing.allocator, cwd_path_absolute, runfiles_path_absolute);
    defer std.testing.allocator.free(runfiles_path);

    var directory = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16)
        try Directory.init(std.testing.allocator, std.Io.Threaded.global_single_threaded.io(), runfiles_path)
    else
        try Directory.init(std.testing.allocator, runfiles_path);
    defer directory.deinit(std.testing.allocator);

    {
        const filepath = try directory.rlocationUnmappedAlloc(std.testing.allocator, .{
            .repo = "",
            .path = "_repo_mapping",
        });
        defer std.testing.allocator.free(filepath);
        try std.testing.expect(std.fs.path.isAbsolute(filepath));
        // TODO[AH] test normalized path (no '..', '/' sep, lower-case Windows)
        const content = try testutil.readAbsoluteFileAlloc(std.testing.allocator, filepath, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("_repo_mapping", content);
    }

    {
        const filepath = try directory.rlocationUnmappedAlloc(std.testing.allocator, .{
            .repo = "my_workspace",
            .path = "some/package/some_file",
        });
        defer std.testing.allocator.free(filepath);
        try std.testing.expect(std.fs.path.isAbsolute(filepath));
        // TODO[AH] test normalized path (no '..', '/' sep, lower-case Windows)
        const content = try testutil.readAbsoluteFileAlloc(std.testing.allocator, filepath, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("some_file", content);
    }
}
