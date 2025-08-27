const builtin = @import("builtin");
const std = @import("std");
const runfiles = @import("runfiles");

fn getEnvVar(allocator: std.mem.Allocator, key: []const u8) !?[]const u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => null,
        else => |e_| return e_,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var r = try runfiles.Runfiles.create(.{ .allocator = allocator }) orelse
        return error.RunfilesNotFound;
    defer r.deinit(allocator);

    const rpath = try getEnvVar(allocator, "DATA") orelse return error.EnvVarNotFoundDATA;
    defer allocator.free(rpath);

    const file_path = try r
        .withSourceRepo("")
        .rlocationAlloc(allocator, rpath) orelse
        return error.RLocationNotFound;
    defer allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(content);

    if (builtin.zig_version.major == 0 and builtin.zig_version.minor >= 15) {
        var buffer: [512]u8 = undefined;
        var writer = std.fs.File.stdout().writer(&buffer);
        const stdout = &writer.interface;
        try stdout.print("data: {s}", .{content});
        try stdout.flush();
    } else {
        try std.io.getStdOut().writer().print("data: {s}", .{content});
    }
}

test "read data file" {
    var r = try runfiles.Runfiles.create(.{ .allocator = std.testing.allocator }) orelse
        return error.RunfilesNotFound;
    defer r.deinit(std.testing.allocator);

    const rpath = try getEnvVar(std.testing.allocator, "DATA") orelse return error.EnvVarNotFoundDATA;
    defer std.testing.allocator.free(rpath);

    const file_path = try r
        .withSourceRepo("")
        .rlocationAlloc(std.testing.allocator, rpath) orelse
        return error.RLocationNotFound;
    defer std.testing.allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(std.testing.allocator, 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}

test "resolve external dependency rpath" {
    var r = try runfiles.Runfiles.create(.{ .allocator = std.testing.allocator }) orelse
        return error.RunfilesNotFound;
    defer r.deinit(std.testing.allocator);

    const rpath = try getEnvVar(std.testing.allocator, "DEPENDENCY_DATA") orelse return error.EnvVarNotFoundDEPENDENCY_DATA;
    defer std.testing.allocator.free(rpath);

    const file_path = try r
        .withSourceRepo("")
        .rlocationAlloc(std.testing.allocator, rpath) orelse
        return error.RLocationNotFound;
    defer std.testing.allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(std.testing.allocator, 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello from dependency!\n", content);
}

test "read data file in dependency Zig module" {
    const content = try @import("module_with_data").readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello from transitive dependency!\n", content);
}

test "runfiles in nested binary" {
    var r = try runfiles.Runfiles.create(.{ .allocator = std.testing.allocator }) orelse
        return error.RunfilesNotFound;
    defer r.deinit(std.testing.allocator);

    const rpath = try getEnvVar(std.testing.allocator, "BINARY") orelse return error.EnvVarNotFoundBINARY;
    defer std.testing.allocator.free(rpath);

    const binary_path = try r
        .withSourceRepo("")
        .rlocationAlloc(std.testing.allocator, rpath) orelse
        return error.RLocationNotFound;
    defer std.testing.allocator.free(binary_path);

    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    const data_rpath = try getEnvVar(std.testing.allocator, "DATA") orelse return error.EnvVarNotFoundBINARY;
    defer std.testing.allocator.free(data_rpath);
    try env.put("DATA", data_rpath);
    try r.environment(&env);

    const run = if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 11)
        std.ChildProcess.exec
    else if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 12)
        std.ChildProcess.run
    else
        std.process.Child.run;
    const result = try run(.{
        .allocator = std.testing.allocator,
        .argv = &[_][]const u8{binary_path},
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stdout);
    defer std.testing.allocator.free(result.stderr);

    std.log.warn("stderr: {s}", .{result.stderr});
    const Term = if (builtin.zig_version.major == 0 and builtin.zig_version.minor < 13)
        std.ChildProcess.Term
    else
        std.process.Child.Term;
    try std.testing.expectEqual(Term{ .Exited = 0 }, result.term);

    try std.testing.expectEqualStrings("data: Hello World!\n", result.stdout);
}
