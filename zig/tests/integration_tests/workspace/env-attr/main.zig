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

    const env_inherit: ?[]const u8 = std.process.getEnvVarOwned(allocator, "ENV_INHERIT") catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
    defer if (env_inherit) |value| allocator.free(value);

    if (env_attr) |value| {
        if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
            var buffer: [512]u8 = undefined;
            var writer = std.Io.File.stdout().writer(
                std.Io.Threaded.global_single_threaded.io(),
                &buffer,
            );
            const stdout = &writer.interface;
            try stdout.print("ENV_ATTR: '{s}'\n", .{value});
            try stdout.flush();
        } else {
            var buffer: [512]u8 = undefined;
            var writer = std.fs.File.stdout().writer(&buffer);
            const stdout = &writer.interface;
            try stdout.print("ENV_ATTR: '{s}'\n", .{value});
            try stdout.flush();
        }
    }
    if (env_inherit) |value| {
        if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16) {
            var buffer: [512]u8 = undefined;
            var writer = std.Io.File.stdout().writer(
                std.Io.Threaded.global_single_threaded.io(),
                &buffer,
            );
            const stdout = &writer.interface;
            try stdout.print("ENV_INHERIT: '{s}'\n", .{value});
            try stdout.flush();
        } else {
            var buffer: [512]u8 = undefined;
            var writer = std.fs.File.stdout().writer(&buffer);
            const stdout = &writer.interface;
            try stdout.print("ENV_INHERIT: '{s}'\n", .{value});
            try stdout.flush();
        }
    }
}
