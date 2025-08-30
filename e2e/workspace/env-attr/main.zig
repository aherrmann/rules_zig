const builtin = @import("builtin");
const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const env_attr: ?[]const u8 = std.process.getEnvVarOwned(allocator, "ENV_ATTR") catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
    defer if (env_attr) |value| allocator.free(value);

    const env_genrule: ?[]const u8 = std.process.getEnvVarOwned(allocator, "ENV_GENRULE") catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
    defer if (env_genrule) |value| allocator.free(value);

    if (env_attr) |value| {
        if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
            var buffer: [512]u8 = undefined;
            var writer = std.fs.File.stdout().writer(&buffer);
            const stdout = &writer.interface;
            try stdout.print("ENV_ATTR: '{s}'\n", .{value});
            try stdout.flush();
        } else {
            try std.io.getStdOut().writer().print("ENV_ATTR: '{s}'\n", .{value});
        }
    }
    if (env_genrule) |value| {
        if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
            var buffer: [512]u8 = undefined;
            var writer = std.fs.File.stdout().writer(&buffer);
            const stdout = &writer.interface;
            try stdout.print("ENV_GENRULE: '{s}'\n", .{value});
            try stdout.flush();
        } else {
            try std.io.getStdOut().writer().print("ENV_GENRULE: '{s}'\n", .{value});
        }
    }
}

test "bazel controlled env var" {
    const value = try std.process.getEnvVarOwned(std.testing.allocator, "ENV_ATTR");
    defer std.testing.allocator.free(value);

    try std.testing.expectEqualStrings("42", value);
}
