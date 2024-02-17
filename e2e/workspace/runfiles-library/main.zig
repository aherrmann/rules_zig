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

    try std.io.getStdOut().writer().print("data: {s}", .{content});
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

    const result = try std.ChildProcess.exec(.{
        .allocator = std.testing.allocator,
        .argv = &[_][]const u8{binary_path},
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stdout);
    defer std.testing.allocator.free(result.stderr);

    std.log.warn("stderr: {s}", .{result.stderr});
    try std.testing.expectEqual(std.ChildProcess.Term{ .Exited = 0 }, result.term);
    try std.testing.expectEqualStrings("data: Hello World!\n", result.stdout);
}
