//! Configure a Zig package's `build.zig` and emit its public module graph as
//! JSON, for translation into Bazel `zig_library` targets.
//!
//! Usage: configurer --zig <zig> --build-root <dir> [--system-integration NAME ...]
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
//!         "generated_source": ..., "link_libc": true, "link_libcpp": true,
//!         "csrcs": [...], "include_dirs": [...], "system_libs": [...], "unsupported": [...],  // each present only when set/non-empty
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
//!
//! The `link_libc`/`link_libcpp` fields are emitted (as `true`) only when the
//! module links the C / C++ standard library, e.g. via
//! `b.addModule(..., .{ .link_libc = true })` or `module.linkSystemLibrary("c",
//! .{})`; they are omitted otherwise.
//!
//! The `csrcs` field lists the module's vendored C sources, each with its
//! per-file `flags` and an optional `language`. The `include_dirs` field lists
//! the module's own include directories, each tagged by `kind` (`path`,
//! `path_system`, or `path_after`). The `system_libs` field lists the names of
//! non-libc system libraries the module links (`linkSystemLibrary`); the
//! importer requires each to be mapped to a `cc_library` via a
//! `zig_packages.system_library` annotation. Each `--system-integration NAME`
//! argument pre-enables the named optional system integration before the build
//! runs, so the package's `systemIntegrationOption(NAME)` returns true and its
//! guarded `linkSystemLibrary` calls run (surfacing as `system_libs` entries).
//! The `unsupported` field lists human-readable descriptions of C or link
//! constructs the importer cannot represent (assembly, prebuilt objects,
//! generated config headers, linked compile steps, ...) and causes failure if
//! present.

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
    var system_integrations: std.ArrayList([]const u8) = .empty;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (mem.eql(u8, args[i], "--zig")) {
            zig_exe = nextArg(args, &i);
        } else if (mem.eql(u8, args[i], "--build-root")) {
            build_root_sub_path = nextArg(args, &i);
        } else if (mem.eql(u8, args[i], "--system-integration")) {
            try system_integrations.append(arena, nextArg(args, &i));
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

    for (system_integrations.items) |name| {
        try graph.system_integration_options.put(arena, name, .user_enabled);
    }

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
        if (module.link_libc == true) {
            try json.objectField("link_libc");
            try json.write(true);
        }
        if (module.link_libcpp == true) {
            try json.objectField("link_libcpp");
            try json.write(true);
        }
        try emitC(arena, &json, module);
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

const CSource = struct {
    path: []const u8,
    flags: []const []const u8,
    language: ?[]const u8,
};

const IncludeDir = struct {
    kind: []const u8,
    path: []const u8,
};

fn joinPath(arena: Allocator, base: []const u8, sub: []const u8) ![]const u8 {
    if (base.len == 0) return sub;
    return std.fmt.allocPrint(arena, "{s}/{s}", .{ base, sub });
}

fn languageName(language: ?Build.Module.CSourceLanguage) ?[]const u8 {
    return if (language) |l| @tagName(l) else null;
}

fn appendIncludeDir(
    arena: Allocator,
    include_dirs: *std.ArrayList(IncludeDir),
    unsupported: *std.ArrayList([]const u8),
    kind: []const u8,
    lazy_path: LazyPath,
) !void {
    if (lazyPathString(lazy_path)) |path| {
        try include_dirs.append(arena, .{ .kind = kind, .path = path });
    } else {
        try unsupported.append(arena, "an include path with a generated or out-of-package location");
    }
}

fn emitC(arena: Allocator, json: *std.json.Stringify, module: *Build.Module) !void {
    var csrcs: std.ArrayList(CSource) = .empty;
    var include_dirs: std.ArrayList(IncludeDir) = .empty;
    var system_libs: std.ArrayList([]const u8) = .empty;
    var unsupported: std.ArrayList([]const u8) = .empty;

    for (module.link_objects.items) |link_object| switch (link_object) {
        .c_source_file => |c| {
            if (lazyPathString(c.file)) |path| {
                try csrcs.append(arena, .{ .path = path, .flags = c.flags, .language = languageName(c.language) });
            } else {
                try unsupported.append(arena, "a C source file with a generated or out-of-package path");
            }
        },
        .c_source_files => |c| {
            if (lazyPathString(c.root)) |root_path| {
                for (c.files) |file| {
                    try csrcs.append(arena, .{ .path = try joinPath(arena, root_path, file), .flags = c.flags, .language = languageName(c.language) });
                }
            } else {
                try unsupported.append(arena, "C source files with a generated or out-of-package root");
            }
        },
        .system_lib => |lib| try system_libs.append(arena, lib.name),
        .static_path => try unsupported.append(arena, "a precompiled object or static library (`addObjectFile`)"),
        .assembly_file => try unsupported.append(arena, "an assembly source file"),
        .win32_resource_file => try unsupported.append(arena, "a Win32 resource file"),
        .other_step => try unsupported.append(arena, "a linked compile step (`linkLibrary`/`addObject`)"),
    };

    for (module.include_dirs.items) |include_dir| switch (include_dir) {
        .path => |lp| try appendIncludeDir(arena, &include_dirs, &unsupported, "path", lp),
        .path_system => |lp| try appendIncludeDir(arena, &include_dirs, &unsupported, "path_system", lp),
        .path_after => |lp| try appendIncludeDir(arena, &include_dirs, &unsupported, "path_after", lp),
        .embed_path => try unsupported.append(arena, "an embed include path (`addEmbedPath`)"),
        .framework_path, .framework_path_system => try unsupported.append(arena, "a framework include path"),
        .config_header_step => try unsupported.append(arena, "a generated config header (`addConfigHeader`)"),
        .other_step => try unsupported.append(arena, "an include path from a linked compile step"),
    };

    if (csrcs.items.len > 0) {
        try json.objectField("csrcs");
        try json.beginArray();
        for (csrcs.items) |c| {
            try json.beginObject();
            try json.objectField("path");
            try json.write(c.path);
            try json.objectField("flags");
            try json.beginArray();
            for (c.flags) |flag| try json.write(flag);
            try json.endArray();
            try json.objectField("language");
            try json.write(c.language);
            try json.endObject();
        }
        try json.endArray();
    }

    if (include_dirs.items.len > 0) {
        try json.objectField("include_dirs");
        try json.beginArray();
        for (include_dirs.items) |inc| {
            try json.beginObject();
            try json.objectField("kind");
            try json.write(inc.kind);
            try json.objectField("path");
            try json.write(inc.path);
            try json.endObject();
        }
        try json.endArray();
    }

    if (system_libs.items.len > 0) {
        try json.objectField("system_libs");
        try json.beginArray();
        for (system_libs.items) |name| try json.write(name);
        try json.endArray();
    }

    if (unsupported.items.len > 0) {
        try json.objectField("unsupported");
        try json.beginArray();
        for (unsupported.items) |u| try json.write(u);
        try json.endArray();
    }
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
