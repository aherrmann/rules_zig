const std = @import("std");

/// Location of the Bazel workspace directory under test.
const BIT_WORKSPACE_DIR = "BIT_WORKSPACE_DIR";

/// Location of the Bazel binary.
const BIT_BAZEL_BINARY = "BIT_BAZEL_BINARY";

/// Bazel integration testing context.
///
/// Provides access to the Bazel binary and the workspace directory under test.
const BitContext = struct {
    workspace_path: []const u8,
    bazel_path: []const u8,

    pub fn init() !BitContext {
        const workspace_path = std.os.getenv(BIT_WORKSPACE_DIR) orelse {
            std.log.err("Required environment variable not found: {s}", .{BIT_WORKSPACE_DIR});
            return error.EnvironmentVariableNotFound;
        };
        const bazel_path = std.os.getenv(BIT_BAZEL_BINARY) orelse {
            std.log.err("Required environment variable not found: {s}", .{BIT_BAZEL_BINARY});
            return error.EnvironmentVariableNotFound;
        };
        return BitContext{
            .workspace_path = workspace_path,
            .bazel_path = bazel_path,
        };
    }

    pub const BazelResult = struct {
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
        },
    ) !BazelResult {
        var argv = try std.testing.allocator.alloc([]const u8, args.argv.len + 1);
        defer std.testing.allocator.free(argv);
        argv[0] = self.bazel_path;
        for (args.argv) |arg, i| {
            argv[i + 1] = arg;
        }
        const result = try std.ChildProcess.exec(.{
            .allocator = std.testing.allocator,
            .argv = argv,
            .cwd = self.workspace_path,
        });
        return BazelResult{
            .term = result.term,
            .stdout = result.stdout,
            .stderr = result.stderr,
        };
    }
};

test "zig_binary prints Hello World!" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "run", "//:binary" },
    });
    defer result.deinit();

    try std.testing.expectEqual(std.ChildProcess.Term{ .Exited = 0 }, result.term);
    try std.testing.expectEqualStrings("Hello World!\n", result.stdout);
}

test "succeeding zig_test passes" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "test", "//:test-succeeds" },
    });
    defer result.deinit();

    try std.testing.expectEqual(std.ChildProcess.Term{ .Exited = 0 }, result.term);
}

test "failing zig_test fails" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "test", "//:test-fails" },
    });
    defer result.deinit();

    // See https://bazel.build/run/scripts for Bazel exit codes.
    try std.testing.expectEqual(std.ChildProcess.Term{ .Exited = 3 }, result.term);
}

test "target build mode defaults to Debug" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "run", "//:print_build_mode" },
    });
    defer result.deinit();

    try std.testing.expectEqual(std.ChildProcess.Term{ .Exited = 0 }, result.term);
    try std.testing.expectEqualStrings("Debug", result.stdout);
}

test "exec build mode defaults to Debug" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:exec_build_mode" },
    });
    defer result.deinit();

    try std.testing.expectEqual(std.ChildProcess.Term{ .Exited = 0 }, result.term);

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const build_mode = try workspace.readFileAlloc(std.testing.allocator, "bazel-bin/exec_build_mode.out", 16);
    defer std.testing.allocator.free(build_mode);
    try std.testing.expectEqualStrings("Debug", build_mode);
}

test "target build mode can be set on the command line" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "run", "//:print_build_mode", "--@rules_zig//zig/settings:mode=release_small" },
    });
    defer result.deinit();

    try std.testing.expectEqual(std.ChildProcess.Term{ .Exited = 0 }, result.term);
    try std.testing.expectEqualStrings("ReleaseSmall", result.stdout);
}

test "exec build mode can be set on the command line" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:exec_build_mode", "--@rules_zig//zig/settings:mode=release_small" },
    });
    defer result.deinit();

    try std.testing.expectEqual(std.ChildProcess.Term{ .Exited = 0 }, result.term);

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const build_mode = try workspace.readFileAlloc(std.testing.allocator, "bazel-bin/exec_build_mode.out", 16);
    defer std.testing.allocator.free(build_mode);
    try std.testing.expectEqualStrings("ReleaseSmall", build_mode);
}
