const std = @import("std");
const builtin = @import("builtin");
const log = std.log.scoped(.runfiles);

const discovery = @import("discovery.zig");
const Directory = @import("Directory.zig");
const Manifest = @import("Manifest.zig");
const RepoMapping = @import("RepoMapping.zig");
const RPath = @import("RPath.zig");

const Runfiles = @This();

implementation: Implementation,
repo_mapping: ?RepoMapping,

/// Quoting the runfiles design:
///
/// > Every language's library will have a similar interface: a Create method
/// > that inspects the environment and/or `argv[0]` to determine the runfiles
/// > strategy (manifest-based or directory-based; see below), initializes
/// > runfiles handling and returns a Runfiles object
pub fn create(options: discovery.DiscoverOptions) !Runfiles {
    var implementation = discover: {
        const result = try discovery.discoverRunfiles(options) orelse
            return error.RunfilesNotFound;
        switch (result) {
            .manifest => |path| {
                defer options.allocator.free(path);
                var manifest = try Manifest.init(options.allocator, path);
                break :discover Implementation{ .manifest = manifest };
            },
            .directory => |path| {
                defer options.allocator.free(path);
                var directory = try Directory.init(options.allocator, path);
                break :discover Implementation{ .directory = directory };
            },
        }
    };
    errdefer implementation.deinit(options.allocator);

    var repo_mapping: ?RepoMapping = try loadRepoMapping(options.allocator, &implementation);

    return Runfiles{
        .implementation = implementation,
        .repo_mapping = repo_mapping,
    };
}

pub fn deinit(self: *Runfiles, allocator: std.mem.Allocator) void {
    self.implementation.deinit(allocator);
    if (self.repo_mapping) |*repo_mapping| repo_mapping.deinit(allocator);
}

/// Quoting the runfiles design:
///
/// > Every language's library will have a similar interface: an
/// > Rlocation(string) method that expects a runfiles-root-relative path
/// > (case-sensitive on Linux/macOS, case-insensitive on Windows) and returns
/// > the absolute path of the file, which is normalized (and lowercase on
/// > Windows) and uses "/" as directory separator on every platform (including
/// > Windows)
///
/// TODO: Rpath validation is not yet implemented.
///
/// TODO: Path normalization, in particular lower-case and '/' normalization on
///   Windows, is not yet implemented.
pub fn rlocation(
    self: *const Runfiles,
    allocator: std.mem.Allocator,
    rpath: []const u8,
    source: []const u8,
) !?[]const u8 {
    var repo: []const u8 = "";
    var path: []const u8 = rpath;
    if (std.mem.indexOfScalar(u8, rpath, '/')) |pos| {
        repo = rpath[0..pos];
        path = rpath[pos + 1 ..];
        if (self.repo_mapping) |repo_mapping| {
            if (repo_mapping.lookup(.{ .source = source, .target = repo })) |mapped|
                repo = mapped;
            // NOTE, the spec states that we should fail if no mapping is found
            // and the repo name is not canonical. However, this always fails
            // in WORKSPACE mode and is apparently an issue in the spec and
            // common runfiles library implementations do not follow this
            // pattern.
        }
    }
    return try self.implementation.rlocationUnmapped(allocator, .{
        .repo = repo,
        .path = path,
    });
}

fn loadRepoMapping(allocator: std.mem.Allocator, implementation: *const Implementation) !?RepoMapping {
    // Bazel <7 with bzlmod disabled does not generate a repo-mapping.
    const msg_not_found = "No repository mapping found. " ++
        "This is likely an error if you are using Bazel version >=7 with bzlmod enabled.";

    const path = try implementation.rlocationUnmapped(allocator, .{
        .repo = "",
        .path = "_repo_mapping",
    }) orelse {
        log.warn(msg_not_found, .{});
        return null;
    };
    defer allocator.free(path);

    if (std.fs.cwd().access(path, .{}) == error.FileNotFound) {
        log.warn(msg_not_found, .{});
        return null;
    }

    return try RepoMapping.init(allocator, path);
}

const Implementation = union(discovery.Strategy) {
    manifest: Manifest,
    directory: Directory,

    pub fn deinit(self: *Implementation, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .manifest => |*manifest| manifest.deinit(allocator),
            .directory => |*directory| directory.deinit(allocator),
        }
    }

    pub fn rlocationUnmapped(
        self: *const Implementation,
        allocator: std.mem.Allocator,
        rpath: RPath,
    ) !?[]const u8 {
        switch (self.*) {
            .manifest => |*manifest| {
                const path = manifest.rlocationUnmapped(rpath) orelse
                    return null;
                return try allocator.dupe(u8, path);
            },
            .directory => |*directory| {
                return try directory.rlocationUnmapped(allocator, rpath);
            },
        }
    }
};

test "Runfiles from manifest" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile("test.repo_mapping",
        \\,my_module,my_workspace
        \\,other_module,other~3.4.5
        \\their_module~1.2.3,another_module,other~3.4.5
    );
    try tmp.dir.makePath("some/package");
    try tmp.dir.writeFile("some/package/some_file", "some_content");
    try tmp.dir.makePath("other/package");
    try tmp.dir.writeFile("other/package/other_file", "other_content");
    {
        var manifest_file = try tmp.dir.createFile("test.runfiles_manifest", .{});
        defer manifest_file.close();
        var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        try manifest_file.writer().print("_repo_mapping {s}\n", .{try tmp.dir.realpath("test.repo_mapping", &buf)});
        try manifest_file.writer().print("my_workspace/some/package/some_file {s}\n", .{try tmp.dir.realpath("some/package/some_file", &buf)});
        try manifest_file.writer().print("other~3.4.5/other/package/other_file {s}\n", .{try tmp.dir.realpath("other/package/other_file", &buf)});
    }
    const manifest_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles_manifest");
    defer std.testing.allocator.free(manifest_path);

    var runfiles = try Runfiles.create(.{
        .allocator = std.testing.allocator,
        .manifest = manifest_path,
    });
    defer runfiles.deinit(std.testing.allocator);

    {
        const file_path = try runfiles.rlocation(
            std.testing.allocator,
            "my_module/some/package/some_file",
            "",
        ) orelse
            return error.TestRLocationNotFound;
        defer std.testing.allocator.free(file_path);
        try std.testing.expect(std.fs.path.isAbsolute(file_path));
        const content = try std.fs.cwd().readFileAlloc(std.testing.allocator, file_path, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("some_content", content);
    }

    {
        const file_path = try runfiles.rlocation(
            std.testing.allocator,
            "other_module/other/package/other_file",
            "",
        ) orelse
            return error.TestRLocationNotFound;
        defer std.testing.allocator.free(file_path);
        try std.testing.expect(std.fs.path.isAbsolute(file_path));
        const content = try std.fs.cwd().readFileAlloc(std.testing.allocator, file_path, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("other_content", content);
    }

    {
        const file_path = try runfiles.rlocation(
            std.testing.allocator,
            "another_module/other/package/other_file",
            "their_module~1.2.3",
        ) orelse
            return error.TestRLocationNotFound;
        defer std.testing.allocator.free(file_path);
        try std.testing.expect(std.fs.path.isAbsolute(file_path));
        const content = try std.fs.cwd().readFileAlloc(std.testing.allocator, file_path, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("other_content", content);
    }
}

test "Runfiles from directory" {
    if (builtin.os.tag == .windows)
        // Windows does not support symlinks out of the box.
        return error.SkipZigTest;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile("test.repo_mapping",
        \\,my_module,my_workspace
        \\,other_module,other~3.4.5
        \\their_module~1.2.3,another_module,other~3.4.5
    );
    try tmp.dir.makePath("some/package");
    try tmp.dir.writeFile("some/package/some_file", "some_content");
    try tmp.dir.makePath("other/package");
    try tmp.dir.writeFile("other/package/other_file", "other_content");
    {
        var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        try tmp.dir.makeDir("test.runfiles");
        try tmp.dir.symLink(
            try tmp.dir.realpath("test.repo_mapping", &buf),
            "test.runfiles/_repo_mapping",
            .{},
        );
        try tmp.dir.makePath("test.runfiles/my_workspace/some/package");
        try tmp.dir.symLink(
            try tmp.dir.realpath("some/package/some_file", &buf),
            "test.runfiles/my_workspace/some/package/some_file",
            .{},
        );
        try tmp.dir.makePath("test.runfiles/other~3.4.5/other/package");
        try tmp.dir.symLink(
            try tmp.dir.realpath("other/package/other_file", &buf),
            "test.runfiles/other~3.4.5/other/package/other_file",
            .{},
        );
    }
    const directory_path = try tmp.dir.realpathAlloc(std.testing.allocator, "test.runfiles");
    defer std.testing.allocator.free(directory_path);

    var runfiles = try Runfiles.create(.{
        .allocator = std.testing.allocator,
        .directory = directory_path,
    });
    defer runfiles.deinit(std.testing.allocator);

    {
        const file_path = try runfiles.rlocation(
            std.testing.allocator,
            "my_module/some/package/some_file",
            "",
        ) orelse
            return error.TestRLocationNotFound;
        defer std.testing.allocator.free(file_path);
        try std.testing.expect(std.fs.path.isAbsolute(file_path));
        const content = try std.fs.cwd().readFileAlloc(std.testing.allocator, file_path, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("some_content", content);
    }

    {
        const file_path = try runfiles.rlocation(
            std.testing.allocator,
            "other_module/other/package/other_file",
            "",
        ) orelse
            return error.TestRLocationNotFound;
        defer std.testing.allocator.free(file_path);
        try std.testing.expect(std.fs.path.isAbsolute(file_path));
        const content = try std.fs.cwd().readFileAlloc(std.testing.allocator, file_path, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("other_content", content);
    }

    {
        const file_path = try runfiles.rlocation(
            std.testing.allocator,
            "another_module/other/package/other_file",
            "their_module~1.2.3",
        ) orelse
            return error.TestRLocationNotFound;
        defer std.testing.allocator.free(file_path);
        try std.testing.expect(std.fs.path.isAbsolute(file_path));
        const content = try std.fs.cwd().readFileAlloc(std.testing.allocator, file_path, 4096);
        defer std.testing.allocator.free(content);
        try std.testing.expectEqualStrings("other_content", content);
    }
}
