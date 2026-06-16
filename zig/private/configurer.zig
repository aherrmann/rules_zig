//! Configure a Zig package's `build.zig` and emit its public module graph as
//! JSON, for translation into Bazel `zig_library` targets.
//!
//! Usage: configurer --zig <zig> --build-root <dir>
//!
//! Modeled on `lib/compiler/configurer.zig`: it sets up a `std.Build`, runs the
//! package's `build` function, then walks the module import graph (seeded by the
//! modules registered via `b.addModule`) instead of serializing the build graph.
//! Following imports transitively reaches the modules of in-tree sub-tree path
//! dependencies, whose `build.zig` runs in a sub-builder. The package's
//! `build.zig` is provided as the `pkg` module and its dependency table as the
//! `deps` module, both wired in at compile time.
//!
//! The emitted JSON has the shape:
//!
//!     {"modules": [{"name": ..., "package": <hash>, "root_source": ...,
//!         "imports": [{"name": ..., "module": ..., "package": <hash>}]}]}
//!
//! A module's `package` is the Zig hash (or sub-tree key) of the package that
//! owns it, or the empty string for the root package being configured. An
//! import's `package` identifies the owner of the imported module likewise. An
//! import's `name` is the name the importer uses (`@import(name)`), while its
//! `module` is the imported module's own registered name; the two differ when a
//! module is imported under an alias.
//!
//! A module whose root source is produced by `b.addOptions()` has no file in the
//! package tree; for these the `generated_source` field carries the step's
//! accumulated source so the importer can materialize it as a static file.

const std = @import("std");
const Io = std.Io;
const Build = std.Build;
const LazyPath = Build.LazyPath;
const Allocator = std.mem.Allocator;
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

    try emit(arena, io, builder);
}

const ModuleSet = std.AutoArrayHashMapUnmanaged(*Build.Module, void);

/// Collect `module` and every module it transitively imports, deduplicated by
/// identity. Imports cross into sub-builders, so this reaches the modules of
/// in-tree sub-tree path dependencies in addition to the root package's own.
fn collect(arena: Allocator, modules: *ModuleSet, module: *Build.Module) !void {
    const gop = try modules.getOrPut(arena, module);
    if (gop.found_existing) return;
    for (module.import_table.values()) |imported| try collect(arena, modules, imported);
}

/// The name a module is registered under in its owning package. Anonymous
/// modules (created via `b.createModule` rather than `b.addModule`) have no
/// registered name, so synthesize a stable one from the module's position in the
/// deduplicated set; its generated target and every import edge referencing it go
/// through this function and so agree.
fn moduleName(arena: Allocator, modules: *const ModuleSet, module: *Build.Module) ![]const u8 {
    var it = module.owner.modules.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* == module) return entry.key_ptr.*;
    }
    return std.fmt.allocPrint(arena, "__anon_{d}", .{modules.getIndex(module).?});
}

fn emit(arena: Allocator, io: Io, builder: *Build) !void {
    var modules: ModuleSet = .empty;
    for (builder.modules.values()) |module| try collect(arena, &modules, module);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(io, &stdout_buffer);
    const writer = &stdout.interface;

    var json: std.json.Stringify = .{ .writer = writer };
    try json.beginObject();
    try json.objectField("modules");
    try json.beginArray();
    for (modules.keys()) |module| {
        try json.beginObject();
        try json.objectField("name");
        try json.write(try moduleName(arena, &modules, module));
        try json.objectField("package");
        try json.write(module.owner.pkg_hash);
        try json.objectField("root_source");
        try json.write(lazyPathString(module.root_source_file));
        if (generatedOptionsSource(builder, module.root_source_file)) |source| {
            try json.objectField("generated_source");
            try json.write(source);
        }
        try json.objectField("imports");
        try json.beginArray();
        for (module.import_table.keys(), module.import_table.values()) |import_name, imported| {
            try json.beginObject();
            try json.objectField("name");
            try json.write(import_name);
            try json.objectField("module");
            try json.write(try moduleName(arena, &modules, imported));
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

/// If `lazy_path` is the generated output of a `b.addOptions()` step, return its
/// accumulated source. The options source is a self-contained set of `pub const`
/// declarations fully determined once `build` has run, so it can be materialized
/// as a static file instead of being produced by a build step — which the
/// importer cannot run. Other generated paths return null (and the module is
/// dropped, as it has no static source).
fn generatedOptionsSource(builder: *Build, lazy_path: ?LazyPath) ?[]const u8 {
    const generated = switch (lazy_path orelse return null) {
        .generated => |generated| generated,
        else => return null,
    };
    if (generated.up != 0 or generated.sub_path.len != 0) return null;
    const step = builder.graph.generated_files.items[@intFromEnum(generated.index)];
    if (step.tag != .options) return null;
    const options: *Build.Step.Options = @fieldParentPtr("step", step);
    return options.contents.items;
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
