const std = @import("std");
const integration_testing = @import("integration_testing");
const BitContext = integration_testing.BitContext;

const Fixture = struct {
    name: []const u8,
    url_placeholder: []const u8,
    hash_placeholder: []const u8,
};

const fixtures = [_]Fixture{
    .{ .name = "leaf", .url_placeholder = "__LEAF_URL__", .hash_placeholder = "__LEAF_HASH__" },
    .{ .name = "host", .url_placeholder = "__HOST_URL__", .hash_placeholder = "__HOST_HASH__" },
};

test "Zig packages are imported from file:// tarballs" {
    const ctx = try BitContext.init();
    defer ctx.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Pack each fixture (built by the inner nightly toolchain) into a tarball and
    // resolve the consumer manifest's URL/hash placeholders to it.
    var replacements: [fixtures.len * 2][2][]const u8 = undefined;
    for (fixtures, 0..) |fixture, i| {
        const dir = try std.fmt.allocPrint(allocator, "{s}/fixtures/{s}", .{ ctx.workspace_path, fixture.name });
        const tarball = try std.fmt.allocPrint(allocator, "{s}/{s}.tar", .{ ctx.workspace_path, fixture.name });

        const pack = try ctx.exec_bazel(.{
            .argv = &[_][]const u8{ "run", "//tools:pack", "--", dir, tarball },
        });
        defer pack.deinit();
        try std.testing.expect(pack.success);

        const hash = try allocator.dupe(u8, std.mem.trim(u8, pack.stdout, " \t\r\n"));
        const url = try std.fmt.allocPrint(allocator, "file://{s}", .{tarball});
        replacements[i * 2] = .{ fixture.url_placeholder, url };
        replacements[i * 2 + 1] = .{ fixture.hash_placeholder, hash };
    }
    try ctx.patchWorkspaceFile("build.zig.zon", &replacements);

    // The importer fetches, configures, and exposes each package (including the
    // sub-tree path dependency of `host`) as a module that the binary imports.
    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{ "build", "//:binary" },
    });
    defer result.deinit();
    try std.testing.expect(result.success);
}
