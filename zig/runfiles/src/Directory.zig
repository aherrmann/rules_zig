//! Implements the directory based runfiles strategy as defined in the
//! [runfiles design][runfiles-design].
//!
//! [runfiles-design]: https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub

const std = @import("std");

const RPath = @import("RPath.zig");

const Directory = @This();

path: []const u8,

pub fn init(allocator: std.mem.Allocator, path: []const u8) !Directory {
    var absolute = try std.fs.cwd().realpathAlloc(allocator, path);
    errdefer allocator.free(absolute);
    // TODO[AH] Implement OS specific normalization, e.g. Windows lower-case.
    return .{ .path = absolute };
}

pub fn deinit(self: *Directory, allocator: std.mem.Allocator) void {
    allocator.free(self.path);
}

pub fn rlocationUnmapped(
    self: *const Directory,
    allocator: std.mem.Allocator,
    rpath: RPath,
) ![]const u8 {
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
    try tmp.dir.makePath("test.runfiles/my_workspace/some/package");
    try tmp.dir.writeFile("test.runfiles/_repo_mapping", "_repo_mapping");
    try tmp.dir.writeFile("test.runfiles/my_workspace/some/package/some_file", "some_file");

    const cwd_path_absolute = try std.fs.cwd().realpathAlloc(std.testing.allocator, ".");
    defer std.testing.allocator.free(cwd_path_absolute);
    const runfiles_path_absolute = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles");
    defer std.testing.allocator.free(runfiles_path_absolute);
    const runfiles_path = try std.fs.path.relative(std.testing.allocator, cwd_path_absolute, runfiles_path_absolute);
    defer std.testing.allocator.free(runfiles_path);

    var directory = try Directory.init(std.testing.allocator, runfiles_path);
    defer directory.deinit(std.testing.allocator);

    {
        const filepath = try directory.rlocationUnmapped(std.testing.allocator, .{
            .repo = "",
            .path = "_repo_mapping",
        });
        defer std.testing.allocator.free(filepath);
        try std.testing.expect(std.fs.path.isAbsolute(filepath));
        // TODO[AH] test normalized path (no '..', '/' sep, lower-case Windows)
        const file = try std.fs.openFileAbsolute(filepath, .{});
        defer file.close();
        const content = try file.readToEndAlloc(std.testing.allocator, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("_repo_mapping", content);
    }

    {
        const filepath = try directory.rlocationUnmapped(std.testing.allocator, .{
            .repo = "my_workspace",
            .path = "some/package/some_file",
        });
        defer std.testing.allocator.free(filepath);
        try std.testing.expect(std.fs.path.isAbsolute(filepath));
        // TODO[AH] test normalized path (no '..', '/' sep, lower-case Windows)
        const file = try std.fs.openFileAbsolute(filepath, .{});
        defer file.close();
        const content = try file.readToEndAlloc(std.testing.allocator, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("some_file", content);
    }
}
