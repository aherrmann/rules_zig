const builtin = @import("builtin");
const std = @import("std");

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) !?[]u8 {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        const key_z = try allocator.dupeZ(u8, key);
        defer allocator.free(key_z);
        const value = std.c.getenv(key_z.ptr) orelse return null;
        return try allocator.dupe(u8, std.mem.span(value));
    }
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}

fn printEnv(env_value: ?[]const u8, name: []const u8) !void {
    const value = env_value orelse return;
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
        var buffer: [512]u8 = undefined;
        var writer = std.Io.File.stdout().writer(
            std.Io.Threaded.global_single_threaded.io(),
            &buffer,
        );
        const stdout = &writer.interface;
        try stdout.print("{s}: '{s}'\n", .{ name, value });
        try stdout.flush();
    } else {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("{s}: '{s}'\n", .{ name, value });
        try stdout.flush();
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    try printEnv(try getEnvVarOwned(allocator, "ENV_ATTR"), "ENV_ATTR");
    try printEnv(try getEnvVarOwned(allocator, "ENV_INHERIT"), "ENV_INHERIT");
}
