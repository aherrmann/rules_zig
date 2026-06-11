//! Resolve a Zig package dependency graph by recursively parsing `build.zig.zon`
//! manifests, and emit the merged graph as JSON on stdout.
//!
//! Usage: zon2json <pkg-dir> <build.zig.zon>...
//!
//! `<pkg-dir>` is the local package directory (`zig build --pkg-dir`) that holds
//! the fetched URL dependencies, each unpacked under `<pkg-dir>/<hash>`. The
//! remaining arguments are the root manifests to resolve.
//!
//! Packages are keyed by their Zig hash (URL dependencies) or by their resolved
//! absolute path (path dependencies). The emitted JSON has the shape:
//!
//!     {
//!       "roots": [{"deps": {"<name>": "<key>"}}],
//!       "packages": {"<key>": {"url": ..., "path": ..., "paths": [...], "deps": {"<name>": "<key>"}}}
//!     }

const std = @import("std");
const Zoir = std.zig.Zoir;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Dep = struct {
    name: []const u8,
    url: ?[]const u8 = null,
    hash: ?[]const u8 = null,
    path: ?[]const u8 = null,
};

const Manifest = struct {
    deps: []const Dep,
    paths: []const []const u8,
};

const Edge = struct {
    name: []const u8,
    key: []const u8,
};

const Package = struct {
    url: ?[]const u8,
    path: ?[]const u8,
    paths: []const []const u8,
    deps: []const Edge,
};

const Resolved = struct {
    key: []const u8,
    url: ?[]const u8,
    path: ?[]const u8,
    dir: []const u8,
};

const Walker = struct {
    arena: Allocator,
    io: Io,
    pkg_dir: []const u8,
    packages: std.StringArrayHashMapUnmanaged(Package) = .empty,

    fn resolveDep(walker: *Walker, dep: Dep, parent_dir: []const u8) !Resolved {
        if (dep.url) |url| {
            const hash = dep.hash orelse fatal("URL dependency '{s}' is missing a hash", .{dep.name});
            return .{
                .key = hash,
                .url = url,
                .path = null,
                .dir = try std.fs.path.join(walker.arena, &.{ walker.pkg_dir, hash }),
            };
        }
        if (dep.path) |rel| {
            const dir = try std.fs.path.resolve(walker.arena, &.{ parent_dir, rel });
            return .{ .key = dir, .url = null, .path = dir, .dir = dir };
        }
        fatal("dependency '{s}' has neither a url nor a path", .{dep.name});
    }

    fn resolveEdges(walker: *Walker, manifest: Manifest, dir: []const u8) ![]const Edge {
        var edges: std.ArrayList(Edge) = .empty;
        for (manifest.deps) |dep| {
            const resolved = try walker.resolveDep(dep, dir);
            try edges.append(walker.arena, .{ .name = dep.name, .key = resolved.key });
            try walker.walk(resolved);
        }
        return edges.items;
    }

    fn walk(walker: *Walker, resolved: Resolved) anyerror!void {
        const gop = try walker.packages.getOrPut(walker.arena, resolved.key);
        if (gop.found_existing) return;
        gop.value_ptr.* = .{ .url = resolved.url, .path = resolved.path, .paths = &.{}, .deps = &.{} };

        const manifest_path = try std.fs.path.join(walker.arena, &.{ resolved.dir, "build.zig.zon" });
        const manifest = try parseManifest(walker.arena, walker.io, manifest_path);
        const edges = try walker.resolveEdges(manifest, resolved.dir);

        walker.packages.getPtr(resolved.key).?.* = .{
            .url = resolved.url,
            .path = resolved.path,
            .paths = manifest.paths,
            .deps = edges,
        };
    }
};

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) fatal("usage: zon2json <pkg-dir> <build.zig.zon>...", .{});

    var walker: Walker = .{ .arena = arena, .io = io, .pkg_dir = args[1] };

    var roots: std.ArrayList([]const Edge) = .empty;
    for (args[2..]) |root_path| {
        const dir = std.fs.path.dirname(root_path) orelse ".";
        const manifest = try parseManifest(arena, io, root_path);
        try roots.append(arena, try walker.resolveEdges(manifest, dir));
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(io, &stdout_buffer);
    const writer = &stdout.interface;

    var json: std.json.Stringify = .{ .writer = writer };
    try json.beginObject();

    try json.objectField("roots");
    try json.beginArray();
    for (roots.items) |edges| {
        try json.beginObject();
        try json.objectField("deps");
        try writeEdges(&json, edges);
        try json.endObject();
    }
    try json.endArray();

    try json.objectField("packages");
    try json.beginObject();
    for (walker.packages.keys(), walker.packages.values()) |key, package| {
        try json.objectField(key);
        try json.beginObject();
        try json.objectField("url");
        try json.write(package.url);
        try json.objectField("path");
        try json.write(package.path);
        try json.objectField("paths");
        try json.write(package.paths);
        try json.objectField("deps");
        try writeEdges(&json, package.deps);
        try json.endObject();
    }
    try json.endObject();

    try json.endObject();
    try writer.writeByte('\n');
    try writer.flush();
}

fn writeEdges(json: *std.json.Stringify, edges: []const Edge) !void {
    try json.beginObject();
    for (edges) |edge| {
        try json.objectField(edge.name);
        try json.write(edge.key);
    }
    try json.endObject();
}

fn parseManifest(arena: Allocator, io: Io, path: []const u8) !Manifest {
    const source = try std.Io.Dir.cwd().readFileAllocOptions(io, path, arena, .unlimited, .of(u8), 0);

    const ast = try std.zig.Ast.parse(arena, source, .zon);
    const zoir = try std.zig.ZonGen.generate(arena, ast, .{});
    if (zoir.compile_errors.len != 0) fatal("'{s}' is not valid ZON", .{path});

    var deps: std.ArrayList(Dep) = .empty;
    var paths: std.ArrayList([]const u8) = .empty;

    switch (Zoir.Node.Index.root.get(zoir)) {
        .struct_literal => |fields| for (fields.names, 0..) |name, i| {
            const field = name.get(zoir);
            const value = fields.vals.at(@intCast(i));
            if (std.mem.eql(u8, field, "dependencies")) {
                try parseDeps(arena, zoir, value, &deps);
            } else if (std.mem.eql(u8, field, "paths")) {
                try parsePaths(arena, zoir, value, &paths);
            }
        },
        else => fatal("'{s}' does not contain a struct", .{path}),
    }

    return .{ .deps = deps.items, .paths = paths.items };
}

fn parseDeps(arena: Allocator, zoir: Zoir, index: Zoir.Node.Index, deps: *std.ArrayList(Dep)) !void {
    const fields = switch (index.get(zoir)) {
        .struct_literal => |fields| fields,
        else => return,
    };
    for (fields.names, 0..) |name, i| {
        var dep: Dep = .{ .name = name.get(zoir) };
        switch (fields.vals.at(@intCast(i)).get(zoir)) {
            .struct_literal => |entry| for (entry.names, 0..) |key, j| {
                const value = entry.vals.at(@intCast(j));
                const field = key.get(zoir);
                if (std.mem.eql(u8, field, "url")) {
                    dep.url = stringOf(zoir, value);
                } else if (std.mem.eql(u8, field, "hash")) {
                    dep.hash = stringOf(zoir, value);
                } else if (std.mem.eql(u8, field, "path")) {
                    dep.path = stringOf(zoir, value);
                }
            },
            else => {},
        }
        try deps.append(arena, dep);
    }
}

fn parsePaths(arena: Allocator, zoir: Zoir, index: Zoir.Node.Index, paths: *std.ArrayList([]const u8)) !void {
    switch (index.get(zoir)) {
        .array_literal => |elements| for (0..elements.len) |i| {
            try paths.append(arena, stringOf(zoir, elements.at(@intCast(i))));
        },
        else => {},
    }
}

fn stringOf(zoir: Zoir, index: Zoir.Node.Index) []const u8 {
    return switch (index.get(zoir)) {
        .string_literal => |string| string,
        else => "",
    };
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print("zon2json: " ++ format ++ "\n", args);
    std.process.exit(1);
}
