const std = @import("std");

const RepoMapping = @import("RepoMapping.zig");

const Self = @This();

directory: []const u8,
repo_mapping: RepoMapping,

fn getEnvVar(allocator: std.mem.Allocator, key: []const u8) !?[]const u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}

fn discoverRunfiles(allocator: std.mem.Allocator) ![]const u8 {
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

pub fn create(allocator: std.mem.Allocator) !Self {
    const runfiles_path = try discoverRunfiles(allocator);

    const repo_mapping_path = try rlocationUnmapped(allocator, runfiles_path, "", "_repo_mapping");
    defer allocator.free(repo_mapping_path);

    return Self{
        .directory = runfiles_path,
        .repo_mapping = try RepoMapping.init(allocator, repo_mapping_path),
    };
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.free(self.directory);
    self.repo_mapping.deinit(allocator);
}

fn rlocationUnmapped(
    allocator: std.mem.Allocator,
    runfiles_directory: []const u8,
    repo: []const u8,
    path: []const u8,
) ![]const u8 {
    return try std.fs.path.join(allocator, &[_][]const u8{
        runfiles_directory,
        repo,
        path,
    });
}

pub fn rlocation(
    self: *const Self,
    allocator: std.mem.Allocator,
    rpath: []const u8,
) ![]const u8 {
    var repo: []const u8 = "";
    var path: []const u8 = rpath;
    if (std.mem.indexOfScalar(u8, rpath, '/')) |pos| {
        repo = rpath[0..pos];
        path = rpath[pos + 1 ..];
        if (self.repo_mapping.lookup(.{ .source = "", .target = repo })) |mapped|
            repo = mapped;
        // NOTE, the spec states that we should fail if no mapping is found and
        // the repo name is not canonical. However, this always fails in
        // WORKSPACE mode and is apparently an issue in the spec and common
        // runfiles library implementations do not follow this pattern.
    }
    return try rlocationUnmapped(allocator, self.directory, repo, path);
}
