const builtin = @import("builtin");
const std = @import("std");
const integration_testing = @import("integration_testing");
const BitContext = integration_testing.BitContext;

test "Zig distribution is fetched from a mirror" {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor < 15) {
        return error.SkipZigTest;
    }

    const ctx = try BitContext.init();

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

    var workspace = try std.fs.cwd().openDir(ctx.workspace_path, .{});
    defer workspace.close();

    const bes_file = try workspace.openFile("bes.json", .{});
    defer bes_file.close();

    var bes_buffer: [4096]u8 = undefined;
    var bes_reader = bes_file.reader(&bes_buffer);
    const bes = &bes_reader.interface;

    var line_buffer = std.array_list.Managed(u8).init(std.testing.allocator);
    defer line_buffer.deinit();
    var line_writer = line_buffer.writer();
    var adapter = line_writer.adaptToNewApi(&.{});
    const line = &adapter.new_interface;

    const expected_url_prefix = "https://pkg.machengine.org/zig/zig";
    var fetch_used_mirror = false;

    while (true) {
        line_buffer.clearRetainingCapacity();
        _ = bes.streamDelimiter(line, '\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        bes.toss(1);

        const trimmed_line = std.mem.trim(u8, line_buffer.items, " \t\r\n");
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
}
