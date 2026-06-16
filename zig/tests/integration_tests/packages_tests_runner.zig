const std = @import("std");
const integration_testing = @import("integration_testing");
const BitContext = integration_testing.BitContext;

// A manifest inside a fixture whose URL-dependency placeholders to fill with
// already-packed fixtures' url+hash.
const Patch = struct {
    manifest: []const u8 = "build.zig.zon",
    deps: []const []const u8,
};

const Package = struct {
    name: []const u8,
    patches: []const Patch = &.{},
};

// Packed in topological order (dependencies first).
const packages = [_]Package{
    .{ .name = "leaf" },
    .{ .name = "host", .patches = &.{.{ .manifest = "libs/foo/build.zig.zon", .deps = &.{"leaf"} }} },
    .{ .name = "base" },
    .{ .name = "bottom", .patches = &.{.{ .deps = &.{"base"} }} },
    .{ .name = "left", .patches = &.{.{ .deps = &.{"bottom"} }} },
    .{ .name = "right", .patches = &.{.{ .deps = &.{"bottom"} }} },
    .{ .name = "top", .patches = &.{.{ .deps = &.{ "left", "right" } }} },
    .{ .name = "multi" },
    .{ .name = "pruned" },
    .{ .name = "libv1" },
    .{ .name = "libv2" },
    .{ .name = "lazyleaf" },
    .{ .name = "lazyhost", .patches = &.{.{ .deps = &.{"lazyleaf"} }} },
};

const Consumer = struct {
    manifest: []const u8,
    deps: []const []const u8,
};

// Manifests that resolve dependencies via `zig_packages.from_file`.
const consumers = [_]Consumer{
    .{ .manifest = "build.zig.zon", .deps = &.{ "leaf", "host", "top", "multi", "pruned", "libv1", "lazyhost" } },
    .{ .manifest = "child/build.zig.zon", .deps = &.{ "leaf", "libv2" } },
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
        for (pkg.patches) |patch| {
            const manifest = try std.fmt.allocPrint(allocator, "fixtures/{s}/{s}", .{ pkg.name, patch.manifest });
            try ctx.patchWorkspaceFile(manifest, try depReplacements(allocator, patch.deps, &urls, &hashes));
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

// Runs after the positive test above, tarballs are packed and consumer
// manifests are patched. Breaks one thing at a time, asserts the build fails as
// expected, and restores the original.
test "the importer rejects invalid package configurations" {
    const ctx = try BitContext.init();
    defer ctx.deinit();

    // A declared hash that does not match the fetched package.
    try ctx.patchWorkspaceFile("build.zig.zon", &.{.{ "leaf-0.0.0-", "leaf-0.0.0-x" }});
    try expectBuildFailure(ctx, "hash mismatch");
    try ctx.patchWorkspaceFile("build.zig.zon", &.{.{ "leaf-0.0.0-x", "leaf-0.0.0-" }});

    // A path dependency whose `build.zig.zon` is not provided via `from_file`.
    const greeter_manifest = "path_deps/greeter/build.zig.zon";
    try ctx.patchWorkspaceFile(greeter_manifest, &.{.{ "../message", "../../fixtures/leaf" }});
    try expectBuildFailure(ctx, "has no provided manifest");
    try ctx.patchWorkspaceFile(greeter_manifest, &.{.{ "../../fixtures/leaf", "../message" }});

    // `zig_dep` referencing a dependency the manifest does not declare.
    const greeter_build = "path_deps/greeter/BUILD.bazel";
    try ctx.patchWorkspaceFile(greeter_build, &.{
        .{ "\"zig_deps\")", "\"zig_dep\", \"zig_deps\")" },
        .{ "deps = zig_deps()", "deps = [zig_dep(\"nonexistent\")]" },
    });
    try expectBuildFailure(ctx, "declares no dependency");
    try ctx.patchWorkspaceFile(greeter_build, &.{
        .{ "\"zig_dep\", \"zig_deps\")", "\"zig_deps\")" },
        .{ "deps = [zig_dep(\"nonexistent\")]", "deps = zig_deps()" },
    });
}

fn expectBuildFailure(ctx: BitContext, expected: []const u8) !void {
    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:binary" },
        .print_on_error = false,
    });
    defer result.deinit();
    if (result.success) {
        std.debug.print("expected build to FAIL (mentioning '{s}') but it succeeded\n", .{expected});
        return error.BuildUnexpectedlySucceeded;
    }
    if (std.mem.indexOf(u8, result.stderr, expected) == null) {
        std.debug.print("expected build failure mentioning '{s}', stderr:\n{s}\n", .{ expected, result.stderr });
        return error.UnexpectedFailureMessage;
    }
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
