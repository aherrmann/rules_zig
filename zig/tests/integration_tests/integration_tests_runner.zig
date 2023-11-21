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

test "zig_binary result should not contain the output base path" {
    if (builtin.os.tag == .macos) {
        // TODO[AH] Avoid output base path on MacOS.
        //   See https://github.com/aherrmann/rules_zig/issues/79
        return error.SkipZigTest;
    }

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

    if (std.mem.indexOf(u8, file_content, output_base)) |start| {
        var end = start;
        while (std.ascii.isPrint(file_content[end])) : (end += 1) {}
        std.debug.print("\nFound output_base in binary at {}-{}: {s}\n", .{ start, end, file_content[start..end] });
        return error.TestExpectNotFound;
    }
}
