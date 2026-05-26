const std = @import("std");
const integration_testing = @import("integration_testing");
const BitContext = integration_testing.BitContext;

test "Zig distribution is fetched from a mirror" {
    const ctx = try BitContext.init();
    defer ctx.deinit();

    const result = try ctx.exec_bazel(.{
        .argv = &[_][]const u8{
            "run",
            "//:binary",
            "--repository_cache=",
            "--experimental_remote_downloader=",
            "--build_event_json_file=bes.json",
        },
    });
    defer result.deinit();

    try std.testing.expect(result.success);

    const bes = try ctx.readWorkspaceFileAlloc("bes.json", 4 * 1024 * 1024);
    defer std.testing.allocator.free(bes);

    const expected_url_prefix = "https://example.com/zig/zig";
    var fetch_used_mirror = false;
    var fetch_used_source_param = false;

    var line_iter = std.mem.splitScalar(u8, bes, '\n');
    while (line_iter.next()) |raw_line| {
        const trimmed_line = std.mem.trim(u8, raw_line, " \t\r\n");
        if (trimmed_line.len > 0) {
            var parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, trimmed_line, .{});
            defer parsed.deinit();

            if (parsed.value == .object) {
                const root_obj = parsed.value.object;
                if (root_obj.get("id")) |id_value| {
                    if (id_value == .object) {
                        if (id_value.object.get("fetch")) |fetch_id| {
                            if (fetch_id == .object) {
                                if (fetch_id.object.get("url")) |url_value| {
                                    if (url_value == .string) {
                                        if (std.mem.startsWith(u8, url_value.string, expected_url_prefix)) {
                                            fetch_used_mirror = true;
                                            fetch_used_source_param = std.mem.endsWith(u8, url_value.string, "?source=github-hermeticbuild-rules_zig");
                                        }
                                    }
                                }
                            }

                            std.debug.print("{s}\n", .{trimmed_line});
                        }
                    }
                }
            }
        }

        if (fetch_used_mirror) {
            break;
        }
    }

    try std.testing.expectEqual(true, fetch_used_mirror);
    try std.testing.expectEqual(true, fetch_used_source_param);
}
