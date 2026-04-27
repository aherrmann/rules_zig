const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) !?[]u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}

fn getEnvVarOwnedFromInit(allocator: std.mem.Allocator, init: std.process.Init, key: []const u8) !?[]u8 {
    const value = init.environ_map.get(key) orelse return null;
    return try allocator.dupe(u8, value);
}

fn printEnv(name: []const u8, value: []const u8) !void {
    var buffer: [512]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    try stdout.print("{s}: '{s}'\n", .{ name, value });
    try stdout.flush();
}

fn printEnv_016(io: anytype, name: []const u8, value: []const u8) !void {
    var buffer: [512]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &writer.interface;
    try stdout.print("{s}: '{s}'\n", .{ name, value });
    try stdout.flush();
}

fn main_pre_016() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const env_attr = try getEnvVarOwned(allocator, "ENV_ATTR");
    defer if (env_attr) |value| allocator.free(value);

    const env_genrule = try getEnvVarOwned(allocator, "ENV_GENRULE");
    defer if (env_genrule) |value| allocator.free(value);

    if (env_attr) |value| try printEnv("ENV_ATTR", value);
    if (env_genrule) |value| try printEnv("ENV_GENRULE", value);
}

fn main_016(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const env_attr = try getEnvVarOwnedFromInit(allocator, init, "ENV_ATTR");
    defer if (env_attr) |value| allocator.free(value);

    const env_genrule = try getEnvVarOwnedFromInit(allocator, init, "ENV_GENRULE");
    defer if (env_genrule) |value| allocator.free(value);

    if (env_attr) |value| try printEnv_016(init.io, "ENV_ATTR", value);
    if (env_genrule) |value| try printEnv_016(init.io, "ENV_GENRULE", value);
}

test "bazel controlled env var" {
    const value = if (is_zig_0_16_or_later)
        try std.testing.environ.getAlloc(std.testing.allocator, "ENV_ATTR")
    else
        try std.process.getEnvVarOwned(std.testing.allocator, "ENV_ATTR");
    defer std.testing.allocator.free(value);

    try std.testing.expectEqualStrings("42", value);
}
