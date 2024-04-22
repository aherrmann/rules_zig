const builtin = @import("builtin");
const std = @import("std");

/// Location of the Bazel workspace directory under test.
const BIT_WORKSPACE_DIR = "BIT_WORKSPACE_DIR";

/// Location of the Bazel binary.
const BIT_BAZEL_BINARY = "BIT_BAZEL_BINARY";

/// Bazel integration testing context.
///
/// Provides access to the Bazel binary and the workspace directory under test.
pub const BitContext = struct {
    workspace_path: []const u8,
    bazel_path: []const u8,
    bzlmod_enabled: bool,

    pub fn init() !BitContext {
        const getenv = if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 11)
            std.os.getenv
        else
            std.posix.getenv;
        const workspace_path = getenv(BIT_WORKSPACE_DIR) orelse {
            std.log.err("Required environment variable not found: {s}", .{BIT_WORKSPACE_DIR});
            return error.EnvironmentVariableNotFound;
        };
        const bazel_path = getenv(BIT_BAZEL_BINARY) orelse {
            std.log.err("Required environment variable not found: {s}", .{BIT_BAZEL_BINARY});
            return error.EnvironmentVariableNotFound;
        };
        const bzlmod_enabled = if (getenv("BZLMOD_ENABLED")) |val|
            std.mem.eql(u8, val, "true")
        else
            false;
        return BitContext{
            .workspace_path = workspace_path,
            .bazel_path = bazel_path,
            .bzlmod_enabled = bzlmod_enabled,
        };
    }

    pub const BazelResult = struct {
        success: bool,
        term: std.ChildProcess.Term,
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
            omit_bzlmod_flag: bool = false,
            extra_env: ?*const std.process.EnvMap = null,
        },
    ) !BazelResult {
        var argc = 1 + args.argv.len;
        if (self.bzlmod_enabled and !args.omit_bzlmod_flag) {
            argc += 1;
        }
        var argv = try std.testing.allocator.alloc([]const u8, argc);
        defer std.testing.allocator.free(argv);
        argv[0] = self.bazel_path;
        for (args.argv, 0..) |arg, i| {
            argv[i + 1] = arg;
        }
        if (self.bzlmod_enabled and !args.omit_bzlmod_flag) {
            argv[argc - 1] = "--enable_bzlmod";
        }
        var env_map: ?std.process.EnvMap = null;
        defer if (env_map) |*env| env.deinit();
        if (args.extra_env) |extra_env| {
            env_map = try std.process.getEnvMap(std.testing.allocator);
            var iter = extra_env.iterator();
            while (iter.next()) |item|
                try env_map.?.put(item.key_ptr.*, item.value_ptr.*);
        }
        const run = if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 11)
            std.ChildProcess.exec
        else
            std.ChildProcess.run;
        const result = try run(.{
            .allocator = std.testing.allocator,
            .argv = argv,
            .cwd = self.workspace_path,
            .env_map = if (env_map) |*env| env else null,
        });
        const success = switch (result.term) {
            .Exited => |code| code == 0,
            else => false,
        };
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
