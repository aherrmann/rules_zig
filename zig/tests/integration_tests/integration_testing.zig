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

fn termSucceeded(term: Term) bool {
    if (is_zig_0_16_or_later) {
        return switch (term) {
            .exited => |code| code == 0,
            else => false,
        };
    }
    return switch (term) {
        .Exited => |code| code == 0,
        else => false,
    };
}

pub fn currentEnvMap(allocator: std.mem.Allocator) !EnvMap {
    if (is_zig_0_16_or_later) {
        return try std.process.Environ.createMap(std.testing.environ, allocator);
    }
    return try std.process.getEnvMap(allocator);
}

pub fn removeEnv(env_map: *EnvMap, key: []const u8) void {
    if (is_zig_0_16_or_later) {
        _ = env_map.swapRemove(key);
    } else {
        env_map.remove(key);
    }
}

fn getEnvOwned(allocator: std.mem.Allocator, key: []const u8) ![]u8 {
    if (is_zig_0_16_or_later) {
        var env_map = try currentEnvMap(allocator);
        defer env_map.deinit();
        const value = env_map.get(key) orelse return error.EnvironmentVariableNotFound;
        return try allocator.dupe(u8, value);
    }
    return try std.process.getEnvVarOwned(allocator, key);
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

    pub fn openWorkspace(self: BitContext) !WorkspaceDir {
        if (is_zig_0_16_or_later) {
            return try std.Io.Dir.openDirAbsolute(std.testing.io, self.workspace_path, .{});
        }
        return try std.fs.cwd().openDir(self.workspace_path, .{});
    }

    pub fn closeWorkspaceDir(dir: *WorkspaceDir) void {
        if (is_zig_0_16_or_later) {
            dir.close(std.testing.io);
        } else {
            dir.close();
        }
    }

    pub fn openWorkspaceFile(self: BitContext, sub_path: []const u8) !WorkspaceFile {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);

        if (is_zig_0_16_or_later) {
            return try workspace.openFile(std.testing.io, sub_path, .{});
        }
        return try workspace.openFile(sub_path, .{});
    }

    pub fn closeWorkspaceFile(file: *WorkspaceFile) void {
        if (is_zig_0_16_or_later) {
            file.close(std.testing.io);
        } else {
            file.close();
        }
    }

    pub fn readWorkspaceFileAlloc(self: BitContext, sub_path: []const u8, max_bytes: usize) ![]u8 {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);

        if (is_zig_0_16_or_later) {
            return try workspace.readFileAlloc(std.testing.io, sub_path, std.testing.allocator, .limited(max_bytes));
        }
        return try workspace.readFileAlloc(std.testing.allocator, sub_path, max_bytes);
    }

    pub fn workspaceFileExists(self: BitContext, sub_path: []const u8) !bool {
        var file = self.openWorkspaceFile(sub_path) catch |err| switch (err) {
            error.FileNotFound => return false,
            else => |e| return e,
        };
        closeWorkspaceFile(&file);
        return true;
    }

    pub fn workspaceDirExists(self: BitContext, sub_path: []const u8) !bool {
        var workspace = try self.openWorkspace();
        defer closeWorkspaceDir(&workspace);

        var dir = if (is_zig_0_16_or_later)
            workspace.openDir(std.testing.io, sub_path, .{}) catch |err| switch (err) {
                error.FileNotFound => return false,
                else => |e| return e,
            }
        else
            workspace.openDir(sub_path, .{}) catch |err| switch (err) {
                error.FileNotFound => return false,
                else => |e| return e,
            };
        closeWorkspaceDir(&dir);
        return true;
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
        const result = if (is_zig_0_16_or_later)
            try std.process.run(std.testing.allocator, std.testing.io, .{
                .argv = argv,
                .cwd = .{ .path = self.workspace_path },
                .environ_map = if (env_map) |*env| env else null,
            })
        else
            try std.process.Child.run(.{
                .allocator = std.testing.allocator,
                .argv = argv,
                .cwd = self.workspace_path,
                .env_map = if (env_map) |*env| env else null,
            });
        const success = termSucceeded(result.term);
        if (args.print_on_error and !success) {
            std.debug.print("\n{s}\n{s}\n", .{ result.stdout, result.stderr });
        }
        return BazelResult{
            .success = success,
            .term = result.term,
            .stdout = result.stdout,
            .stderr = result.stderr,
        };
    }
};
