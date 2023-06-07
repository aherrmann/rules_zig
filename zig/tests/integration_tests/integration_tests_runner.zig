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
    bzlmod_enabled: bool,

    pub fn init() !BitContext {
        const workspace_path = std.os.getenv(BIT_WORKSPACE_DIR) orelse {
            std.log.err("Required environment variable not found: {s}", .{BIT_WORKSPACE_DIR});
            return error.EnvironmentVariableNotFound;
        };
        const bazel_path = std.os.getenv(BIT_BAZEL_BINARY) orelse {
            std.log.err("Required environment variable not found: {s}", .{BIT_BAZEL_BINARY});
            return error.EnvironmentVariableNotFound;
        };
        const bzlmod_enabled = if (std.os.getenv("BZLMOD_ENABLED")) |val|
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
        },
    ) !BazelResult {
        var argc = 1 + args.argv.len;
        if (self.bzlmod_enabled and !args.omit_bzlmod_flag) {
            argc += 1;
        }
        var argv = try std.testing.allocator.alloc([]const u8, argc);
        defer std.testing.allocator.free(argv);
        argv[0] = self.bazel_path;
        for (args.argv) |arg, i| {
            argv[i + 1] = arg;
        }
        if (self.bzlmod_enabled and !args.omit_bzlmod_flag) {
            argv[argc - 1] = "--enable_bzlmod";
        }
        const result = try std.ChildProcess.exec(.{
            .allocator = std.testing.allocator,
            .argv = argv,
            .cwd = self.workspace_path,
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

test "zig_binary prints Hello World!" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "run", "//:binary" },
    });
    defer result.deinit();

    try std.testing.expect(result.success);
    try std.testing.expectEqualStrings("Hello World!\n", result.stdout);
}

test "succeeding zig_test passes" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "test", "//:test-succeeds" },
    });
    defer result.deinit();

    try std.testing.expect(result.success);
}

test "failing zig_test fails" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "test", "//:test-fails" },
        .print_on_error = false,
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

    try std.testing.expect(result.success);
    try std.testing.expectEqualStrings("Debug", result.stdout);
}

test "exec build mode defaults to Debug" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:exec_build_mode" },
    });
    defer result.deinit();

    try std.testing.expect(result.success);

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

    try std.testing.expect(result.success);
    try std.testing.expectEqualStrings("ReleaseSmall", result.stdout);
}

test "exec build mode can be set on the command line" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:exec_build_mode", "--@rules_zig//zig/settings:mode=release_small" },
    });
    defer result.deinit();

    try std.testing.expect(result.success);

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const build_mode = try workspace.readFileAlloc(std.testing.allocator, "bazel-bin/exec_build_mode.out", 16);
    defer std.testing.allocator.free(build_mode);
    try std.testing.expectEqualStrings("ReleaseSmall", build_mode);
}

test "can compile to target platform aarch64-linux" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:binary", "--platforms=:aarch64-linux" },
    });
    defer result.deinit();

    try std.testing.expect(result.success);

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const file = try workspace.openFile("bazel-bin/binary", .{});
    defer file.close();

    const elf_header = try std.elf.Header.read(file);
    try std.testing.expectEqual(std.elf.EM.AARCH64, elf_header.machine);
}

test "zig_binary result should not contain the output base path" {
    const ctx = try BitContext.init();

    const info_result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "info", "output_base" },
    });
    defer info_result.deinit();

    const output_base = std.mem.trim(u8, info_result.stdout, " \n");

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:binary", "--@rules_zig//zig/settings:mode=debug" },
    });
    defer result.deinit();

    try std.testing.expect(result.success);

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const file = try workspace.openFile("bazel-bin/binary", .{});
    defer file.close();

    const file_content = try file.readToEndAlloc(std.testing.allocator, 1_000_000);
    defer std.testing.allocator.free(file_content);

    try std.testing.expectEqual(@as(?usize, null), std.mem.indexOf(u8, file_content, output_base));
}
