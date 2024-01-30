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

    const env_inherit: ?[]const u8 = std.process.getEnvVarOwned(allocator, "ENV_INHERIT") catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
    defer if (env_inherit) |value| allocator.free(value);

    if (env_attr) |value|
        try std.io.getStdOut().writer().print("ENV_ATTR: '{s}'\n", .{value});
    if (env_inherit) |value|
        try std.io.getStdOut().writer().print("ENV_INHERIT: '{s}'\n", .{value});
}
