const builtin = @import("builtin");
const std = @import("std");
const integration_testing = @import("integration_testing.zig");
const BitContext = integration_testing.BitContext;

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

fn testBinaryShouldNotContainOutputBase(mode: []const u8) !void {
    const ctx = try BitContext.init();

    const info_result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "info", "output_base" },
    });
    defer info_result.deinit();

    const output_base = std.mem.trim(u8, info_result.stdout, " \n");

    const mode_flag = try std.fmt.allocPrint(
        std.testing.allocator,
        "--@rules_zig//zig/settings:mode={s}",
        .{mode},
    );
    defer std.testing.allocator.free(mode_flag);

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:binary", mode_flag },
    });
    defer result.deinit();

    try std.testing.expect(result.success);

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const file = try workspace.openFile("bazel-bin/binary", .{});
    defer file.close();

    const file_content = try file.readToEndAlloc(std.testing.allocator, 64_000_000);
    defer std.testing.allocator.free(file_content);

    if (std.mem.indexOf(u8, file_content, output_base)) |start| {
        var end = start;
        while (std.ascii.isPrint(file_content[end])) : (end += 1) {}
        std.debug.print("\nFound output_base in binary at {}-{}: {s}\n", .{ start, end, file_content[start..end] });
        return error.TestExpectNotFound;
    }
}

test "zig_binary result should not contain the output base path in debug mode" {
    if (true) {
        // TODO[AH] Avoid output base path in debug mode.
        //   See https://github.com/aherrmann/rules_zig/issues/79
        return error.SkipZigTest;
    }

    try testBinaryShouldNotContainOutputBase("debug");
}

test "zig_binary result should not contain the output base path in release_safe mode" {
    if (true) {
        // TODO[AH] Avoid output base path in release_safe mode.
        //   See https://github.com/aherrmann/rules_zig/issues/79
        return error.SkipZigTest;
    }

    try testBinaryShouldNotContainOutputBase("release_safe");
}

test "zig_binary result should not contain the output base path in release_small mode" {
    try testBinaryShouldNotContainOutputBase("release_small");
}

test "zig_binary result should not contain the output base path in release_fast mode" {
    if (true) {
        // TODO[AH] Avoid output base path in release_fast mode.
        //   See https://github.com/aherrmann/rules_zig/issues/79
        return error.SkipZigTest;
    }

    try testBinaryShouldNotContainOutputBase("release_fast");
}

test "zig_target_toolchain attribute dynamic_linker configures the interpreter" {
    const ctx = try BitContext.init();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{
            "build",
            "//custom_interpreter:binary-custom_interpreter",
            "--extra_toolchains=//custom_interpreter:x86_64-linux-custom_interpreter_toolchain",
            "--extra_toolchains=//custom_interpreter:cc_x86_64-linux-custom_interpreter_toolchain",
        },
    });
    defer result.deinit();

    try std.testing.expect(result.success);

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const file = try workspace.openFile("bazel-bin/custom_interpreter/binary-custom_interpreter", .{});
    defer file.close();

    const elf_header = try std.elf.Header.read(file);
    var ph_iter = elf_header.program_header_iterator(file);
    var interp = std.ArrayList(u8).init(std.testing.allocator);
    defer interp.deinit();
    while (try ph_iter.next()) |phdr| {
        if (phdr.p_type == std.elf.PT_INTERP) {
            try file.seekableStream().seekTo(phdr.p_offset);
            try file.reader().streamUntilDelimiter(interp.writer(), 0, null);
            break;
        }
    }

    try std.testing.expectEqualStrings("/custom/loader.so", interp.items);
}

test "zig_binary forwards env attribute environment" {
    const ctx = try BitContext.init();

    var extra_env = std.process.EnvMap.init(std.testing.allocator);
    defer extra_env.deinit();
    try extra_env.put("ENV_INHERIT", "21");

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "run", "//env-attr:binary" },
        .extra_env = &extra_env,
    });
    defer result.deinit();

    try std.testing.expect(result.success);
    try std.testing.expectEqualStrings(
        \\ENV_ATTR: '42'
        \\ENV_INHERIT: '21'
        \\
    , result.stdout);
}

test "zig_test forwards env attribute environment" {
    const ctx = try BitContext.init();

    var extra_env = std.process.EnvMap.init(std.testing.allocator);
    defer extra_env.deinit();
    try extra_env.put("ENV_INHERIT", "21");

    {
        const result = try ctx.exec_bazel(.{
            .argv = &[_][]const u8{ "test", "//env-attr:test" },
            .extra_env = &extra_env,
        });
        defer result.deinit();

        try std.testing.expect(result.success);
    }

    {
        const result = try ctx.exec_bazel(.{
            .argv = &[_][]const u8{ "test", "//env-attr:test-no-inherit" },
            .extra_env = &extra_env,
        });
        defer result.deinit();

        try std.testing.expect(!result.success);
    }
}

test "runfiles library supports manifest mode" {
    const ctx = try BitContext.init();

    // Build the binary with runfiles manifest.
    {
        const result = try ctx.exec_bazel(.{
            .argv = &[_][]const u8{
                "build",                   "//runfiles:binary",
                "--enable_runfiles",       "--nolegacy_external_runfiles",
                "--nobuild_runfile_links", "--build_runfile_manifests",
            },
        });
        defer result.deinit();

        try std.testing.expect(result.success);
    }

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    // Check that no runfiles tree was generated.
    {
        var dir: ?std.fs.Dir = workspace.openDir("bazel-bin/runfiles/binary.runfiles", .{}) catch |e| switch (e) {
            error.FileNotFound => null,
            else => |e_| return e_,
        };
        if (dir) |*dir_| {
            dir_.close();
            return error.RunfilesDirectoryShouldNotExist;
        }
    }

    // Check that the runfiles manifest was generated.
    {
        const file = workspace.openFile("bazel-bin/runfiles/binary.runfiles_manifest", .{}) catch |e| switch (e) {
            error.FileNotFound => return error.RunfilesManifestNotFound,
            else => |e_| return e_,
        };
        file.close();
    }

    // Clean up the environment.
    var env_map = try std.process.getEnvMap(std.testing.allocator);
    defer env_map.deinit();
    env_map.remove("RUNFILES_DIR");
    env_map.remove("RUNFILES_MANIFEST_FILE");

    // Execute the binary.
    const result = try std.ChildProcess.exec(.{
        .allocator = std.testing.allocator,
        .argv = &[_][]const u8{"bazel-bin/runfiles/binary"},
        .cwd_dir = workspace,
        .env_map = &env_map,
    });
    defer std.testing.allocator.free(result.stdout);
    defer std.testing.allocator.free(result.stderr);

    try std.testing.expectEqualStrings("", result.stderr);
    try std.testing.expectEqual(.{ .Exited = 0 }, result.term);
    try std.testing.expectEqualStrings("data: Hello World!\n", result.stdout);
}
