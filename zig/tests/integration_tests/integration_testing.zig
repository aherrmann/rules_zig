const builtin = @import("builtin");
const std = @import("std");

/// Location of the Bazel workspace directory under test.
const BIT_WORKSPACE_DIR = "BIT_WORKSPACE_DIR";

/// Location of the Bazel binary.
const BIT_BAZEL_BINARY = "BIT_BAZEL_BINARY";

const Term = std.process.Child.Term;
pub const EnvMap = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16)
    std.process.Environ.Map
else
    std.process.EnvMap;

pub fn exitedTerm(code: u8) Term {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        return .{ .exited = code };
    }
    return .{ .Exited = code };
}

fn termSucceeded(term: Term) bool {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
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
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        return try std.process.Environ.createMap(std.testing.environ, allocator);
    }
    return try std.process.getEnvMap(allocator);
}

fn getEnvOwned(allocator: std.mem.Allocator, key: []const u8) ![]u8 {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
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
        const result = if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16)
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
