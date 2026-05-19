const builtin = @import("builtin");
const std = @import("std");

const bazel_builtin = @import("bazel_builtin");
const runfiles = @import("runfiles");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

/// https://github.com/zigtools/zls/blob/606a86543362c0072248d8f1ef4a64a5e3f51682/src/build_runner/shared.zig#L6
pub const BuildConfig = struct {
    /// The `dependencies` in `build.zig.zon`.
    dependencies: std.json.ArrayHashMap([]const u8),
    /// The key is the `root_source_file`.
    /// All modules with the same root source file are merged. This limitation may be lifted in the future.
    modules: std.json.ArrayHashMap(Module),
    /// List of all compilations units.
    compilations: []Compile,
    /// The names of all top level steps.
    top_level_steps: []const []const u8,
    available_options: std.json.ArrayHashMap(AvailableOption),

    pub const Module = struct {
        import_table: std.json.ArrayHashMap([]const u8),
        c_macros: []const []const u8,
        include_dirs: []const []const u8,
    };

    pub const Compile = struct {
        /// Key in `BuildConfig.modules`.
        root_module: []const u8,

        // may contain additional information in the future like `target` or `link_libc`.
    };

    /// Equivalent to `std.Build.AvailableOption` which is not accessible because it non-pub.
    pub const AvailableOption = @FieldType(@FieldType(std.Build, "available_options_map").KV, "value");
};

fn processConfigLeaky_pre_016(allocator: std.mem.Allocator, config_string: []const u8) !BuildConfig {
    var config = try std.json.parseFromSliceLeaky(BuildConfig, allocator, config_string, .{});
    try canonicalizeModulesLeaky_pre_016(allocator, &config);
    return config;
}

fn processConfigLeaky_016(allocator: std.mem.Allocator, io: std.Io, config_string: []const u8) !BuildConfig {
    var config = try std.json.parseFromSliceLeaky(BuildConfig, allocator, config_string, .{});
    try canonicalizeModulesLeaky_016(allocator, io, &config);
    return config;
}

// Neovim canonicalizes the path it sends to ZLS, we need to do the same as ZLS will match against the config we generate.
// We canonicalize the following module paths:
//
// {
//   "modules": {
//     "<module-path>": {
//       "import_table": {
//         "<import-name>": "<module-path>"
//       },
//     },
//   },
// }
fn canonicalizeModulesLeaky_pre_016(allocator: std.mem.Allocator, config: *BuildConfig) !void {
    var old_modules = config.modules.map.iterator();
    var new_modules: std.StringArrayHashMapUnmanaged(BuildConfig.Module) = .empty;
    try new_modules.ensureTotalCapacity(allocator, old_modules.len);

    while (old_modules.next()) |entry| {
        const module_name = canonicalizePath_pre_016(allocator, entry.key_ptr.*);
        var module: BuildConfig.Module = entry.value_ptr.*;
        for (module.import_table.map.values()) |*imported_module_path| {
            imported_module_path.* = canonicalizePath_pre_016(allocator, imported_module_path.*);
        }
        try new_modules.put(allocator, module_name, module);
    }

    for (config.compilations) |*compile| {
        compile.root_module = canonicalizePath_pre_016(allocator, compile.root_module);
    }

    config.modules.map = new_modules;
}

fn canonicalizeModulesLeaky_016(allocator: std.mem.Allocator, io: std.Io, config: *BuildConfig) !void {
    var old_modules = config.modules.map.iterator();
    var new_modules: std.StringArrayHashMapUnmanaged(BuildConfig.Module) = .empty;
    try new_modules.ensureTotalCapacity(allocator, old_modules.len);

    while (old_modules.next()) |entry| {
        const module_name = canonicalizePath_016(allocator, io, entry.key_ptr.*);
        var module: BuildConfig.Module = entry.value_ptr.*;
        for (module.import_table.map.values()) |*imported_module_path| {
            imported_module_path.* = canonicalizePath_016(allocator, io, imported_module_path.*);
        }
        try new_modules.put(allocator, module_name, module);
    }

    for (config.compilations) |*compile| {
        compile.root_module = canonicalizePath_016(allocator, io, compile.root_module);
    }

    config.modules.map = new_modules;
}

fn canonicalizePath_pre_016(allocator: std.mem.Allocator, path: []const u8) []const u8 {
    return std.fs.realpathAlloc(allocator, path) catch path;
}

fn canonicalizePath_016(allocator: std.mem.Allocator, io: std.Io, path: []const u8) []const u8 {
    return std.Io.Dir.realPathFileAbsoluteAlloc(io, path, allocator) catch path;
}

fn readFileAlloc_pre_016(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const max_bytes = std.math.maxInt(usize);
    if (std.fs.path.isAbsolutePosix(path)) {
        const file = try std.fs.openFileAbsolute(path, .{});
        defer file.close();
        return try file.readToEndAlloc(allocator, max_bytes);
    }
    return try std.fs.cwd().readFileAlloc(allocator, path, max_bytes);
}

fn readBuildConfig_pre_016(
    allocator: std.mem.Allocator,
    arg_path: []const u8,
) ![]u8 {
    if (std.fs.path.isAbsolutePosix(arg_path)) {
        return readFileAlloc_pre_016(allocator, arg_path);
    }

    var r_ = try runfiles.Runfiles.create(.{
        .allocator = allocator,
    }) orelse return error.RunfilesNotFound;
    defer r_.deinit(allocator);

    const r = r_.withSourceRepo(bazel_builtin.current_repository);

    if (try r.rlocationAlloc(allocator, arg_path)) |config_path| {
        return readFileAlloc_pre_016(allocator, config_path);
    }

    const stripped = if (std.mem.startsWith(u8, arg_path, "./")) arg_path[2..] else arg_path;
    if (try r.rlocationAlloc(allocator, stripped)) |config_path| {
        return readFileAlloc_pre_016(allocator, config_path);
    }

    // Convenience for testing.
    const output = readFileAlloc_pre_016(allocator, arg_path) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };
    if (output) |content| {
        return content;
    }

    return error.BuildConfigNotFound;
}

fn readBuildConfig_016(
    allocator: std.mem.Allocator,
    io: std.Io,
    init: std.process.Init,
    arg_path: []const u8,
) ![]u8 {
    if (std.fs.path.isAbsolutePosix(arg_path)) {
        return std.Io.Dir.cwd().readFileAlloc(io, arg_path, allocator, .unlimited);
    }

    var r_ = try runfiles.Runfiles.create(.{
        .allocator = allocator,
        .io = io,
        .environ_map = init.environ_map,
        .argv = init.minimal.args,
    }) orelse return error.RunfilesNotFound;

    var path_buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const r = r_.withSourceRepo(bazel_builtin.current_repository);

    if (try r.rlocation(arg_path, &path_buf)) |config_path| {
        return std.Io.Dir.cwd().readFileAlloc(io, config_path, allocator, .unlimited);
    }

    const stripped = if (std.mem.startsWith(u8, arg_path, "./")) arg_path[2..] else arg_path;
    if (try r.rlocation(stripped, &path_buf)) |config_path| {
        return std.Io.Dir.cwd().readFileAlloc(io, config_path, allocator, .unlimited);
    }

    // Convenience for testing.
    const output = std.Io.Dir.cwd().readFileAlloc(io, arg_path, allocator, .unlimited) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };
    if (output) |content| {
        return content;
    }

    return error.BuildConfigNotFound;
}

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn main_pre_016() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    if (args.len < 2) {
        return error.MissingBuildConfigArgument;
    }

    const build_workspace_directory = try std.process.getEnvVarOwned(allocator, "BUILD_WORKSPACE_DIRECTORY");
    const execution_root = std.process.getEnvVarOwned(allocator, "BAZEL_EXECUTION_ROOT") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => blk: {
            const output_base_result = try std.process.Child.run(.{
                .allocator = allocator,
                .argv = &.{
                    "bazel",
                    "info",
                    "execution_root",
                },
                .cwd = build_workspace_directory,
            });
            break :blk std.mem.trimEnd(u8, output_base_result.stdout, "\n");
        },
        else => |e| return e,
    };

    var output = try readBuildConfig_pre_016(allocator, args[1]);
    output = try std.mem.replaceOwned(
        u8,
        allocator,
        output,
        "__BUILD_WORKSPACE_DIRECTORY__",
        build_workspace_directory,
    );
    output = try std.mem.replaceOwned(
        u8,
        allocator,
        output,
        "__BAZEL_EXECUTION_ROOT__",
        execution_root,
    );

    var stdout_buf: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &writer.interface;
    if (processConfigLeaky_pre_016(allocator, output)) |config| {
        try std.json.Stringify.value(config, .{}, stdout);
    } else |_| {
        try stdout.writeAll(output);
    }
    try stdout.flush();
}

fn main_016(init: std.process.Init) !void {
    const arena = init.arena;
    const io = init.io;
    const args = try init.minimal.args.toSlice(arena.allocator());

    const build_workspace_directory = init.environ_map.get("BUILD_WORKSPACE_DIRECTORY").?;
    const execution_root = if (init.environ_map.get("BAZEL_EXECUTION_ROOT")) |value|
        value
    else blk: {
        const output_base_result = try std.process.run(arena.allocator(), init.io, .{
            .argv = &.{
                "bazel",
                "info",
                "execution_root",
            },
            .cwd = .{ .path = build_workspace_directory },
        });
        break :blk std.mem.trimEnd(u8, output_base_result.stdout, "\n");
    };

    var output = try readBuildConfig_016(
        arena.allocator(),
        io,
        init,
        args[1],
    );
    output = try std.mem.replaceOwned(
        u8,
        arena.allocator(),
        output,
        "__BUILD_WORKSPACE_DIRECTORY__",
        build_workspace_directory,
    );
    output = try std.mem.replaceOwned(
        u8,
        arena.allocator(),
        output,
        "__BAZEL_EXECUTION_ROOT__",
        execution_root,
    );

    var stdout_buf: [4096]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &stdout_buf);
    if (processConfigLeaky_016(arena.allocator(), io, output)) |config| {
        try std.json.Stringify.value(config, .{}, &writer.interface);
    } else |_| {
        try writer.interface.writeAll(output);
    }
    try writer.flush();
}
