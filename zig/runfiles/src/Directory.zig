//! Implements the directory based runfiles strategy as defined in the
//! [runfiles design][runfiles-design].
//!
//! [runfiles-design]: https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub

const std = @import("std");

const Self = @This();

path: []const u8,

pub fn init(allocator: std.mem.Allocator, path: []const u8) !Self {
    var absolute = try std.fs.cwd().realpathAlloc(allocator, path);
    errdefer allocator.free(absolute);
    // TODO[AH] Implement OS specific normalization, e.g. Windows lower-case.
    return .{ .path = absolute };
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.free(self.path);
}

pub fn rlocationUnmapped(
    self: *const Self,
    allocator: std.mem.Allocator,
    repo: []const u8,
    rpath: []const u8,
) ![]const u8 {
    // TODO[AH] Implement OS specific normalization, e.g. Windows lower-case.
    return try std.fs.path.join(allocator, &[_][]const u8{
        self.path,
        repo,
        rpath,
    });
}
