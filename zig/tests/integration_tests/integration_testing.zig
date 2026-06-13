const builtin = @import("builtin");
const std = @import("std");

/// Location of the Bazel workspace directory under test.
const BIT_WORKSPACE_DIR = "BIT_WORKSPACE_DIR";

/// Location of the Bazel binary.
const BIT_BAZEL_BINARY = "BIT_BAZEL_BINARY";

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

const Term = std.process.Child.Term;
pub const EnvMap = if (is_zig_0_16_or_later)
    std.process.Environ.Map
else
    std.process.EnvMap;
pub const WorkspaceDir = if (is_zig_0_16_or_later)
    std.Io.Dir
else
    std.fs.Dir;
pub const WorkspaceFile = if (is_zig_0_16_or_later)
    std.Io.File
else
    std.fs.File;

pub fn exitedTerm(code: u8) Term {
    if (is_zig_0_16_or_later) {
        return .{ .exited = code };
    }
    return .{ .Exited = code };
}

const termSucceeded = if (is_zig_0_16_or_later) termSucceeded_016 else termSucceeded_pre_016;
pub const currentEnvMap = if (is_zig_0_16_or_later) currentEnvMap_016 else currentEnvMap_pre_016;
pub const removeEnv = if (is_zig_0_16_or_later) removeEnv_016 else removeEnv_pre_016;
const getEnvOwned = if (is_zig_0_16_or_later) getEnvOwned_016 else getEnvOwned_pre_016;

fn termSucceeded_pre_016(term: Term) bool {
    return switch (term) {
        .Exited => |code| code == 0,
        else => false,
    };
}

fn termSucceeded_016(term: Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

fn currentEnvMap_pre_016(allocator: std.mem.Allocator) !EnvMap {
    return try std.process.getEnvMap(allocator);
}

fn currentEnvMap_016(allocator: std.mem.Allocator) !EnvMap {
    return try std.process.Environ.createMap(std.testing.environ, allocator);
}

fn removeEnv_pre_016(env_map: *EnvMap, key: []const u8) void {
    env_map.remove(key);
}

fn removeEnv_016(env_map: *EnvMap, key: []const u8) void {
    _ = env_map.swapRemove(key);
}

fn getEnvOwned_pre_016(allocator: std.mem.Allocator, key: []const u8) ![]u8 {
    return try std.process.getEnvVarOwned(allocator, key);
}

fn getEnvOwned_016(allocator: std.mem.Allocator, key: []const u8) ![]u8 {
    var env_map = try currentEnvMap(allocator);
    defer env_map.deinit();
    const value = env_map.get(key) orelse return error.EnvironmentVariableNotFound;
    return try allocator.dupe(u8, value);
}

/// Bazel integration testing context.
///
/// Provides access to the Bazel binary and the workspace directory under test.
pub const BitContext = struct {
    workspace_path: []const u8,
    bazel_path: []const u8,

    pub fn init() !BitContext {
        const workspace_path = getEnvOwned(std.testing.allocator, BIT_WORKSPACE_DIR) catch |err| switch (err) {
            error.EnvironmentVariableNotFound => {
                std.log.err("Required environment variable not found: {s}", .{BIT_WORKSPACE_DIR});
                return error.EnvironmentVariableNotFound;
            },
            else => |e| return e,
        };
        errdefer std.testing.allocator.free(workspace_path);

        const bazel_path = getEnvOwned(std.testing.allocator, BIT_BAZEL_BINARY) catch |err| switch (err) {
            error.EnvironmentVariableNotFound => {
                std.log.err("Required environment variable not found: {s}", .{BIT_BAZEL_BINARY});
                return error.EnvironmentVariableNotFound;
            },
            else => |e| return e,
        };
        return BitContext{
            .workspace_path = workspace_path,
            .bazel_path = bazel_path,
        };
    }

    pub fn deinit(self: BitContext) void {
        std.testing.allocator.free(self.workspace_path);
        std.testing.allocator.free(self.bazel_path);
    }

    pub const openWorkspace = if (is_zig_0_16_or_later) openWorkspace_016 else openWorkspace_pre_016;
    pub const closeWorkspaceDir = if (is_zig_0_16_or_later) closeWorkspaceDir_016 else closeWorkspaceDir_pre_016;
    pub const openWorkspaceFile = if (is_zig_0_16_or_later) openWorkspaceFile_016 else openWorkspaceFile_pre_016;
    pub const closeWorkspaceFile = if (is_zig_0_16_or_later) closeWorkspaceFile_016 else closeWorkspaceFile_pre_016;
    pub const readWorkspaceFileAlloc = if (is_zig_0_16_or_later) readWorkspaceFileAlloc_016 else readWorkspaceFileAlloc_pre_016;
    pub const workspaceDirExists = if (is_zig_0_16_or_later) workspaceDirExists_016 else workspaceDirExists_pre_016;
    const runBazel = if (is_zig_0_16_or_later) runBazel_016 else runBazel_pre_016;

    fn openWorkspace_pre_016(self: BitContext) !WorkspaceDir {
        return try std.fs.cwd().openDir(self.workspace_path, .{});
    }

    fn openWorkspace_016(self: BitContext) !WorkspaceDir {
        return try std.Io.Dir.openDirAbsolute(std.testing.io, self.workspace_path, .{});
    }

    fn closeWorkspaceDir_pre_016(dir: *WorkspaceDir) void {
        dir.close();
    }

    fn closeWorkspaceDir_016(dir: *WorkspaceDir) void {
        dir.close(std.testing.io);
    }

    fn openWorkspaceFile_pre_016(self: BitContext, sub_path: []const u8) !WorkspaceFile {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);
        return try workspace.openFile(sub_path, .{});
    }

    fn openWorkspaceFile_016(self: BitContext, sub_path: []const u8) !WorkspaceFile {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);
        return try workspace.openFile(std.testing.io, sub_path, .{});
    }

    fn closeWorkspaceFile_pre_016(file: *WorkspaceFile) void {
        file.close();
    }

    fn closeWorkspaceFile_016(file: *WorkspaceFile) void {
        file.close(std.testing.io);
    }

    fn readWorkspaceFileAlloc_pre_016(self: BitContext, sub_path: []const u8, max_bytes: usize) ![]u8 {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);
        return try workspace.readFileAlloc(std.testing.allocator, sub_path, max_bytes);
    }

    fn readWorkspaceFileAlloc_016(self: BitContext, sub_path: []const u8, max_bytes: usize) ![]u8 {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);
        return try workspace.readFileAlloc(std.testing.io, sub_path, std.testing.allocator, .limited(max_bytes));
    }

    pub fn workspaceFileExists(self: BitContext, sub_path: []const u8) !bool {
        var file = self.openWorkspaceFile(sub_path) catch |err| switch (err) {
            error.FileNotFound => return false,
            else => |e| return e,
        };
        closeWorkspaceFile(&file);
        return true;
    }

    fn workspaceDirExists_pre_016(self: BitContext, sub_path: []const u8) !bool {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);

        var dir = workspace.openDir(sub_path, .{}) catch |err| switch (err) {
            error.FileNotFound => return false,
            else => |e| return e,
        };
        closeWorkspaceDir(&dir);
        return true;
    }

    fn workspaceDirExists_016(self: BitContext, sub_path: []const u8) !bool {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);

        var dir = workspace.openDir(std.testing.io, sub_path, .{}) catch |err| switch (err) {
            error.FileNotFound => return false,
            else => |e| return e,
        };
        closeWorkspaceDir(&dir);
        return true;
    }

    pub const writeWorkspaceFile = if (is_zig_0_16_or_later) writeWorkspaceFile_016 else writeWorkspaceFile_pre_016;

    fn writeWorkspaceFile_pre_016(self: BitContext, sub_path: []const u8, content: []const u8) !void {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);
        workspace.deleteFile(sub_path) catch {};
        var file = try workspace.createFile(sub_path, .{});
        defer file.close();
        try file.writeAll(content);
    }

    fn writeWorkspaceFile_016(self: BitContext, sub_path: []const u8, content: []const u8) !void {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);
        workspace.deleteFile(std.testing.io, sub_path) catch {};
        var file = try workspace.createFile(std.testing.io, sub_path, .{});
        defer file.close(std.testing.io);
        var buffer: [4096]u8 = undefined;
        var writer = file.writer(std.testing.io, &buffer);
        try writer.interface.writeAll(content);
        try writer.interface.flush();
    }

    /// Replace each `needle` with its `replacement` in a workspace file, writing
    /// a fresh file so the original source (a symlink in the test sandbox) is
    /// never modified.
    pub fn patchWorkspaceFile(
        self: BitContext,
        sub_path: []const u8,
        replacements: []const [2][]const u8,
    ) !void {
        var content = try self.readWorkspaceFileAlloc(sub_path, 4 * 1024 * 1024);
        for (replacements) |replacement| {
            const patched = try std.mem.replaceOwned(u8, std.testing.allocator, content, replacement[0], replacement[1]);
            std.testing.allocator.free(content);
            content = patched;
        }
        defer std.testing.allocator.free(content);
        try self.writeWorkspaceFile(sub_path, content);
    }

    pub const BazelResult = struct {
        success: bool,
        term: Term,
        stdout: []u8,
        stderr: []u8,

        pub fn deinit(self: BazelResult) void {
            std.testing.allocator.free(self.stdout);
            std.testing.allocator.free(self.stderr);
        }
    };

    pub fn exec_bazel(
        self: BitContext,
        args: struct {
            argv: []const []const u8,
            print_on_error: bool = true,
            extra_env: ?*const EnvMap = null,
        },
    ) !BazelResult {
        const argc = 1 + args.argv.len;
        var argv = try std.testing.allocator.alloc([]const u8, argc);
        defer std.testing.allocator.free(argv);
        argv[0] = self.bazel_path;
        for (args.argv, 0..) |arg, i| {
            argv[i + 1] = arg;
        }
        var env_map: ?EnvMap = null;
        defer if (env_map) |*env| env.deinit();
        if (args.extra_env) |extra_env| {
            env_map = try currentEnvMap(std.testing.allocator);
            var iter = extra_env.iterator();
            while (iter.next()) |item|
                try env_map.?.put(item.key_ptr.*, item.value_ptr.*);
        }
        const result = try runBazel(self, argv, if (env_map) |*env| env else null);
        if (args.print_on_error and !result.success) {
            std.debug.print("\n{s}\n{s}\n", .{ result.stdout, result.stderr });
        }
        return result;
    }

    fn runBazel_pre_016(self: BitContext, argv: []const []const u8, env_map: ?*EnvMap) !BazelResult {
        const result = try std.process.Child.run(.{
            .allocator = std.testing.allocator,
            .argv = argv,
            .cwd = self.workspace_path,
            .env_map = env_map,
        });
        return .{
            .success = termSucceeded(result.term),
            .term = result.term,
            .stdout = result.stdout,
            .stderr = result.stderr,
        };
    }

    fn runBazel_016(self: BitContext, argv: []const []const u8, env_map: ?*EnvMap) !BazelResult {
        const result = try std.process.run(std.testing.allocator, std.testing.io, .{
            .argv = argv,
            .cwd = .{ .path = self.workspace_path },
            .environ_map = env_map,
        });
        return .{
            .success = termSucceeded(result.term),
            .term = result.term,
            .stdout = result.stdout,
            .stderr = result.stderr,
        };
    }
};
