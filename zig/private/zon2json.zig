//! Resolve a Zig package dependency graph by recursively parsing `build.zig.zon`
//! manifests, and emit the merged graph as JSON on stdout.
//!
//! Usage: zon2json <zig> <global-cache> <pkg-dir> <build.zig.zon>...
//!
//! URL dependencies are fetched with `<zig> fetch` into `<global-cache>` as
//! content-addressed tarballs (no source-tree unpacking); their `build.zig.zon`
//! manifests are extracted under `<pkg-dir>/<hash>`. The remaining arguments are
//! the root manifests to resolve. Resolving manifests ourselves (rather than via
//! `zig build --fetch --pkg-dir`) lets path dependencies inside fetched packages
//! resolve relative to the extracted tree.
//!
//! Packages are keyed by their Zig hash (URL dependencies) or by their resolved
//! absolute path (path dependencies), and listed in topological order: a package
//! always precedes any package that lists it as a dependency. The emitted JSON
//! has the shape:
//!
//!     {
//!       "roots": [{"deps": {"<name>": "<key>"}}],
//!       "packages": {"<key>": {"url": ..., "path": ..., "paths": [...], "deps": {"<name>": "<key>"}}}
//!     }

const std = @import("std");
const Zoir = std.zig.Zoir;
const Allocator = std.mem.Allocator;
const Io = std.Io;
const flate = std.compress.flate;
const tar = std.tar;

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
    zig: []const u8,
    global_cache: []const u8,
    pkg_dir: []const u8,
    packages: std.StringArrayHashMapUnmanaged(Package) = .empty,
    visited: std.StringHashMapUnmanaged(void) = .empty,

    fn resolveDep(walker: *Walker, dep: Dep, parent_dir: []const u8) !Resolved {
        if (dep.url) |url| {
            const declared = dep.hash orelse fatal("URL dependency '{s}' is missing a hash", .{dep.name});
            const hash = try walker.fetch(url);
            if (!std.mem.eql(u8, hash, declared)) {
                fatal("hash mismatch for '{s}':\n  declared: {s}\n  fetched:  {s}", .{ dep.name, declared, hash });
            }
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

    /// Fetch a URL package as a content-addressed tarball (no source-tree
    /// unpacking), then extract its `build.zig.zon` manifests into `pkg_dir` so
    /// the walk can resolve the dependency graph from the filesystem.
    fn fetch(walker: *Walker, url: []const u8) ![]const u8 {
        const result = try std.process.run(walker.arena, walker.io, .{
            .argv = &.{ walker.zig, "fetch", "--global-cache-dir", walker.global_cache, url },
        });
        switch (result.term) {
            .exited => |code| if (code != 0) fatal("`zig fetch {s}` failed:\n{s}", .{ url, result.stderr }),
            .signal => |sig| fatal("`zig fetch {s}` killed by signal {d}:\nstdout:\n{s}\nstderr:\n{s}", .{ url, sig, result.stdout, result.stderr }),
            else => |term| fatal("`zig fetch {s}` terminated abnormally ({s}):\n{s}", .{ url, @tagName(term), result.stderr }),
        }
        const hash = try walker.arena.dupe(u8, std.mem.trim(u8, result.stdout, " \t\r\n"));

        const dest = try std.fs.path.join(walker.arena, &.{ walker.pkg_dir, hash });
        if (Io.Dir.cwd().access(walker.io, dest, .{})) |_| return hash else |_| {}
        try walker.extractManifests(hash, dest);
        return hash;
    }

    fn extractManifests(walker: *Walker, hash: []const u8, dest: []const u8) !void {
        const arena = walker.arena;
        const io = walker.io;
        const tarball = try std.fmt.allocPrint(arena, "{s}/p/{s}.tar.gz", .{ walker.global_cache, hash });

        var file = try Io.Dir.cwd().openFile(io, tarball, .{});
        defer file.close(io);
        var read_buffer: [64 * 1024]u8 = undefined;
        var file_reader = file.reader(io, &read_buffer);
        var window: [flate.max_window_len]u8 = undefined;
        var decompress: flate.Decompress = .init(&file_reader.interface, .gzip, &window);

        var name_buffer: [std.fs.max_path_bytes]u8 = undefined;
        var link_name_buffer: [std.fs.max_path_bytes]u8 = undefined;
        var iterator: tar.Iterator = .init(&decompress.reader, .{
            .file_name_buffer = &name_buffer,
            .link_name_buffer = &link_name_buffer,
        });

        // Collect every manifest, tracking the shallowest one's directory as the
        // archive prefix to strip (the tarball nests the package under it).
        const Found = struct { name: []const u8, content: []const u8 };
        var manifests: std.ArrayList(Found) = .empty;
        var prefix: []const u8 = "";
        var have_prefix = false;
        while (try iterator.next()) |entry| {
            if (entry.kind == .directory) continue;
            if (!std.mem.eql(u8, std.fs.path.basename(entry.name), "build.zig.zon")) continue;
            var content: std.Io.Writer.Allocating = .init(arena);
            try iterator.streamRemaining(entry, &content.writer);
            const name = try arena.dupe(u8, entry.name);
            const dir = std.fs.path.dirname(name) orelse "";
            if (!have_prefix or dir.len < prefix.len) {
                prefix = dir;
                have_prefix = true;
            }
            try manifests.append(arena, .{ .name = name, .content = content.written() });
        }

        try Io.Dir.cwd().createDirPath(io, dest);
        var dest_dir = try Io.Dir.cwd().openDir(io, dest, .{});
        defer dest_dir.close(io);
        for (manifests.items) |found| {
            const rel = if (prefix.len == 0) found.name else found.name[prefix.len + 1 ..];
            if (std.fs.path.dirname(rel)) |parent| try dest_dir.createDirPath(io, parent);
            try dest_dir.writeFile(io, .{ .sub_path = rel, .data = found.content });
        }
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
        const gop = try walker.visited.getOrPut(walker.arena, resolved.key);
        if (gop.found_existing) return;

        const manifest_path = try std.fs.path.join(walker.arena, &.{ resolved.dir, "build.zig.zon" });
        const manifest = try parseManifest(walker.arena, walker.io, manifest_path);
        const edges = try walker.resolveEdges(manifest, resolved.dir);

        // Append only after the dependencies have been walked, so `packages` ends
        // up in topological order: a package precedes any package depending on it.
        try walker.packages.put(walker.arena, resolved.key, .{
            .url = resolved.url,
            .path = resolved.path,
            .paths = manifest.paths,
            .deps = edges,
        });
    }
};

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 4) fatal("usage: zon2json <zig> <global-cache> <pkg-dir> <build.zig.zon>...", .{});

    var walker: Walker = .{
        .arena = arena,
        .io = io,
        .zig = args[1],
        .global_cache = args[2],
        .pkg_dir = args[3],
    };

    var roots: std.ArrayList([]const Edge) = .empty;
    for (args[4..]) |root_path| {
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
