const std = @import("std");
const runfiles = @import("runfiles");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var r = try runfiles.Runfiles.create(allocator);
    defer r.deinit(allocator);

    const rpath = std.process.getEnvVarOwned(allocator, "DATA") catch |e| switch (e) {
        error.EnvironmentVariableNotFound => return error.EnvironmentVariableDATANotFound,
        else => |e_| return e_,
    };
    defer allocator.free(rpath);

    const file_path = try r.rlocation(allocator, rpath);
    defer allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(content);

    try std.io.getStdOut().writer().print("data: {s}", .{content});
}

test "read data file" {
    var r = try runfiles.Runfiles.create(std.testing.allocator);
    defer r.deinit(std.testing.allocator);

    const rpath = std.process.getEnvVarOwned(std.testing.allocator, "DATA") catch |e| switch (e) {
        error.EnvironmentVariableNotFound => return error.EnvironmentVariableDATANotFound,
        else => |e_| return e_,
    };
    defer std.testing.allocator.free(rpath);

    const file_path = try r.rlocation(std.testing.allocator, rpath);
    defer std.testing.allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(std.testing.allocator, 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}

test "resolve external dependency rpath" {
    var r = try runfiles.Runfiles.create(std.testing.allocator);
    defer r.deinit(std.testing.allocator);

    const rpath = std.process.getEnvVarOwned(std.testing.allocator, "DEPENDENCY_DATA") catch |e| switch (e) {
        error.EnvironmentVariableNotFound => return error.EnvironmentVariableDEPENDENCY_DATANotFound,
        else => |e_| return e_,
    };
    defer std.testing.allocator.free(rpath);

    const file_path = try r.rlocation(std.testing.allocator, rpath);
    defer std.testing.allocator.free(file_path);

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(std.testing.allocator, 4096);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello from dependency!\n", content);
}
