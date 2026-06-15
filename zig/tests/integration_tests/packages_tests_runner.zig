const std = @import("std");
const integration_testing = @import("integration_testing");
const BitContext = integration_testing.BitContext;

const Package = struct {
    name: []const u8,
    deps: []const []const u8 = &.{},
    // Manifest holding this package's dependency placeholders, relative to the
    // fixture root. `host`'s dependency belongs to its `libs/foo` sub-tree.
    manifest: []const u8 = "build.zig.zon",
};

// Packed in topological order (dependencies first).
const packages = [_]Package{
    .{ .name = "leaf" },
    .{ .name = "host", .deps = &.{"leaf"}, .manifest = "libs/foo/build.zig.zon" },
    .{ .name = "base" },
    .{ .name = "bottom", .deps = &.{"base"} },
    .{ .name = "left", .deps = &.{"bottom"} },
    .{ .name = "right", .deps = &.{"bottom"} },
    .{ .name = "top", .deps = &.{ "left", "right" } },
    .{ .name = "multi" },
};

const Consumer = struct {
    manifest: []const u8,
    deps: []const []const u8,
};

// Manifests that resolve dependencies via `zig_packages.from_file`.
const consumers = [_]Consumer{
    .{ .manifest = "build.zig.zon", .deps = &.{ "leaf", "host", "top", "multi" } },
    .{ .manifest = "child/build.zig.zon", .deps = &.{"leaf"} },
};

test "Zig packages are imported from file:// tarballs" {
    const ctx = try BitContext.init();
    defer ctx.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var urls = std.StringHashMap([]const u8).init(allocator);
    var hashes = std.StringHashMap([]const u8).init(allocator);

    for (packages) |pkg| {
        if (pkg.deps.len > 0) {
            const manifest = try std.fmt.allocPrint(allocator, "fixtures/{s}/{s}", .{ pkg.name, pkg.manifest });
            try ctx.patchWorkspaceFile(manifest, try depReplacements(allocator, pkg.deps, &urls, &hashes));
        }

        const dir = try std.fmt.allocPrint(allocator, "{s}/fixtures/{s}", .{ ctx.workspace_path, pkg.name });
        const tarball = try std.fmt.allocPrint(allocator, "{s}/{s}.tar", .{ ctx.workspace_path, pkg.name });
        const pack = try ctx.exec_bazel(.{
            .argv = &[_][]const u8{ "run", "//tools:pack", "--", dir, tarball },
        });
        defer pack.deinit();
        try std.testing.expect(pack.success);

        try hashes.put(pkg.name, try allocator.dupe(u8, std.mem.trim(u8, pack.stdout, " \t\r\n")));
        try urls.put(pkg.name, try std.fmt.allocPrint(allocator, "file://{s}", .{tarball}));
    }

    for (consumers) |consumer| {
        try ctx.patchWorkspaceFile(consumer.manifest, try depReplacements(allocator, consumer.deps, &urls, &hashes));
    }

    // The importer fetches, configures, and exposes each package (including the
    // sub-tree path dependency of `host` and the transitive chain under `top`)
    // as a module that the binary imports.
    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:binary" },
    });
    defer result.deinit();
    try std.testing.expect(result.success);
}

fn depReplacements(
    allocator: std.mem.Allocator,
    deps: []const []const u8,
    urls: *std.StringHashMap([]const u8),
    hashes: *std.StringHashMap([]const u8),
) ![]const [2][]const u8 {
    const replacements = try allocator.alloc([2][]const u8, deps.len * 2);
    for (deps, 0..) |dep, i| {
        replacements[i * 2] = .{ try placeholder(allocator, dep, "URL"), urls.get(dep).? };
        replacements[i * 2 + 1] = .{ try placeholder(allocator, dep, "HASH"), hashes.get(dep).? };
    }
    return replacements;
}

fn placeholder(allocator: std.mem.Allocator, name: []const u8, kind: []const u8) ![]const u8 {
    const upper = try allocator.alloc(u8, name.len);
    _ = std.ascii.upperString(upper, name);
    return std.fmt.allocPrint(allocator, "__{s}_{s}__", .{ upper, kind });
}
