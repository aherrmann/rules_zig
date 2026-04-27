const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;
const ProcessInit = if (is_zig_0_16_or_later) std.process.Init else void;

pub const main = if (is_zig_0_16_or_later) main_016 else main_pre_016;

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) !?[]u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}

fn getEnvVarOwnedFromInit(allocator: std.mem.Allocator, init: ProcessInit, key: []const u8) !?[]u8 {
    const value = init.environ_map.get(key) orelse return null;
    return try allocator.dupe(u8, value);
}

fn printEnv(env_value: ?[]const u8, name: []const u8) !void {
    const value = env_value orelse return;
    if (is_zig_0_16_or_later) {
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

fn main_pre_016() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    try printEnv(try getEnvVarOwned(allocator, "ENV_ATTR"), "ENV_ATTR");
    try printEnv(try getEnvVarOwned(allocator, "ENV_INHERIT"), "ENV_INHERIT");
}

fn main_016(init: ProcessInit) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    try printEnv(try getEnvVarOwnedFromInit(allocator, init, "ENV_ATTR"), "ENV_ATTR");
    try printEnv(try getEnvVarOwnedFromInit(allocator, init, "ENV_INHERIT"), "ENV_INHERIT");
}
