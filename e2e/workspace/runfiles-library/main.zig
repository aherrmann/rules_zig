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

    var r = try runfiles.Runfiles.create(.{ .allocator = allocator });
    defer r.deinit(allocator);

    const rpath = try getEnvVar(allocator, "DATA") orelse return error.EnvVarNotFoundDATA;
    defer allocator.free(rpath);

    const file_path = try r.rlocationAlloc(allocator, rpath, "") orelse return error.RLocationNotFound;
    defer allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(content);

    try std.io.getStdOut().writer().print("data: {s}", .{content});
}

test "read data file" {
    var r = try runfiles.Runfiles.create(.{ .allocator = std.testing.allocator });
    defer r.deinit(std.testing.allocator);

    const rpath = try getEnvVar(std.testing.allocator, "DATA") orelse return error.EnvVarNotFoundDATA;
    defer std.testing.allocator.free(rpath);

    const file_path = try r.rlocationAlloc(std.testing.allocator, rpath, "") orelse return error.RLocationNotFound;
    defer std.testing.allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(std.testing.allocator, 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}

test "resolve external dependency rpath" {
    var r = try runfiles.Runfiles.create(.{ .allocator = std.testing.allocator });
    defer r.deinit(std.testing.allocator);

    const rpath = try getEnvVar(std.testing.allocator, "DEPENDENCY_DATA") orelse return error.EnvVarNotFoundDEPENDENCY_DATA;
    defer std.testing.allocator.free(rpath);

    const file_path = try r.rlocationAlloc(std.testing.allocator, rpath, "") orelse return error.RLocationNotFound;
    defer std.testing.allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(std.testing.allocator, 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello from dependency!\n", content);
}

test "read data file in dependency Zig package" {
    const content = try @import("package_with_data").readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello from transitive dependency!\n", content);
}
