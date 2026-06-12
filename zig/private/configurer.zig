//! Configure a Zig package's `build.zig` and emit its public module graph as
//! JSON, for translation into Bazel `zig_library` targets.
//!
//! Usage: configurer --zig <zig> --build-root <dir>
//!
//! Modeled on `lib/compiler/configurer.zig`: it sets up a `std.Build`, runs the
//! package's `build` function, then walks `b.modules` (the modules registered
//! via `b.addModule`) instead of serializing the build graph. The package's
//! `build.zig` is provided as the `pkg` module and its dependency table as the
//! `deps` module, both wired in at compile time.
//!
//! The emitted JSON has the shape:
//!
//!     {"modules": [{"name": ..., "root_source": ..., "imports": [
//!         {"name": ..., "root_source": ..., "package": <hash>}]}]}
//!
//! `package` is the Zig hash of the dependency package that owns an imported
//! module, or the empty string for an import within the same package.

const std = @import("std");
const Io = std.Io;
const Build = std.Build;
const LazyPath = Build.LazyPath;
const mem = std.mem;
const process = std.process;

pub const root = @import("pkg");
pub const dependencies = @import("deps");

pub fn main(init: process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(arena);

    var zig_exe: ?[]const u8 = null;
    var build_root_sub_path: ?[]const u8 = null;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (mem.eql(u8, args[i], "--zig")) {
            zig_exe = nextArg(args, &i);
        } else if (mem.eql(u8, args[i], "--build-root")) {
            build_root_sub_path = nextArg(args, &i);
        } else {
            fatal("unrecognized argument: {s}", .{args[i]});
        }
    }

    const zig = zig_exe orelse fatal("missing --zig", .{});
    const build_root_path = build_root_sub_path orelse fatal("missing --build-root", .{});

    var graph: Build.Graph = .{
        .io = io,
        .arena = arena,
        .environ_map = try init.minimal.environ.createMap(arena),
        .host = .{
            .query = .{},
            .result = try std.zig.system.resolveTargetQuery(io, .{}),
        },
        .generated_files = .empty,
        .zig_exe = zig,
        .wip_configuration = .init(arena),
    };
    // Seed the configuration string table so its reserved sentinels resolve:
    // `.empty` must intern at offset 0 and `.root` at offset 1, before any other
    // string.
    const empty_string = try graph.wip_configuration.addString("");
    const root_string = try graph.wip_configuration.addString("root");
    std.debug.assert(empty_string == .empty);
    std.debug.assert(root_string == .root);

    const build_root: Build.Cache.Path = .{
        .root_dir = .{
            .handle = try Io.Dir.cwd().openDir(io, build_root_path, .{}),
            .path = build_root_path,
        },
    };

    const builder = try Build.create(&graph, build_root, dependencies.root_deps);

    try builder.runBuild(root);

    try emit(io, builder);
}

fn emit(io: Io, builder: *Build) !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(io, &stdout_buffer);
    const writer = &stdout.interface;

    var json: std.json.Stringify = .{ .writer = writer };
    try json.beginObject();
    try json.objectField("modules");
    try json.beginArray();
    for (builder.modules.keys(), builder.modules.values()) |name, module| {
        try json.beginObject();
        try json.objectField("name");
        try json.write(name);
        try json.objectField("root_source");
        try json.write(lazyPathString(module.root_source_file));
        try json.objectField("imports");
        try json.beginArray();
        for (module.import_table.keys(), module.import_table.values()) |import_name, imported| {
            try json.beginObject();
            try json.objectField("name");
            try json.write(import_name);
            try json.objectField("root_source");
            try json.write(lazyPathString(imported.root_source_file));
            try json.objectField("package");
            try json.write(imported.owner.pkg_hash);
            try json.endObject();
        }
        try json.endArray();
        try json.endObject();
    }
    try json.endArray();
    try json.endObject();
    try writer.writeByte('\n');
    try writer.flush();
}

fn lazyPathString(lazy_path: ?LazyPath) ?[]const u8 {
    const path = lazy_path orelse return null;
    return switch (path) {
        .src_path => |src| src.sub_path,
        .cwd_relative => |rel| rel,
        .relative => |rel| rel.sub_path,
        else => null,
    };
}

fn nextArg(args: []const [:0]const u8, i: *usize) []const u8 {
    i.* += 1;
    if (i.* >= args.len) fatal("'{s}' requires a value", .{args[i.* - 1]});
    return args[i.*];
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print("configurer: " ++ format ++ "\n", args);
    std.process.exit(1);
}
