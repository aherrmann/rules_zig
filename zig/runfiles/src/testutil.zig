const builtin = @import("builtin");
const std = @import("std");

const is_zig_0_16_or_later = builtin.zig_version.major == 0 and builtin.zig_version.minor >= 16;

fn ownNoSentinel(allocator: std.mem.Allocator, path_z: [:0]u8) ![]u8 {
    defer allocator.free(path_z);
    return try allocator.dupe(u8, path_z);
}

pub fn tmpWriteFile(dir: anytype, sub_path: []const u8, data: []const u8) !void {
    if (is_zig_0_16_or_later) {
        try dir.writeFile(std.testing.io, .{
            .sub_path = sub_path,
            .data = data,
        });
    } else {
        try dir.writeFile(.{
            .sub_path = sub_path,
            .data = data,
        });
    }
}

pub fn tmpMakeDir(dir: anytype, sub_path: []const u8) !void {
    if (is_zig_0_16_or_later) {
        try dir.createDir(std.testing.io, sub_path, .default_dir);
    } else {
        try dir.makeDir(sub_path);
    }
}

pub fn tmpMakePath(dir: anytype, sub_path: []const u8) !void {
    if (is_zig_0_16_or_later) {
        try dir.createDirPath(std.testing.io, sub_path);
    } else {
        try dir.makePath(sub_path);
    }
}

pub fn tmpRealpathAlloc(dir: anytype, allocator: std.mem.Allocator, sub_path: []const u8) ![]u8 {
    if (is_zig_0_16_or_later) {
        return try ownNoSentinel(allocator, try dir.realPathFileAlloc(std.testing.io, sub_path, allocator));
    }
    return try dir.realpathAlloc(allocator, sub_path);
}

pub fn tmpRealpath(dir: anytype, sub_path: []const u8, out_buffer: []u8) ![]const u8 {
    if (is_zig_0_16_or_later) {
        const len = try dir.realPathFile(std.testing.io, sub_path, out_buffer);
        return out_buffer[0..len];
    }
    return try dir.realpath(sub_path, out_buffer);
}

pub fn tmpDeleteFile(dir: anytype, sub_path: []const u8) !void {
    if (is_zig_0_16_or_later) {
        try dir.deleteFile(std.testing.io, sub_path);
    } else {
        try dir.deleteFile(sub_path);
    }
}

pub fn tmpDeleteDir(dir: anytype, sub_path: []const u8) !void {
    if (is_zig_0_16_or_later) {
        try dir.deleteDir(std.testing.io, sub_path);
    } else {
        try dir.deleteDir(sub_path);
    }
}

pub fn tmpSymLink(dir: anytype, target_path: []const u8, sym_link_path: []const u8) !void {
    if (is_zig_0_16_or_later) {
        try dir.symLink(std.testing.io, target_path, sym_link_path, .{});
    } else {
        try dir.symLink(target_path, sym_link_path, .{});
    }
}

pub fn readAbsoluteFileAlloc(allocator: std.mem.Allocator, path: []const u8, limit: usize) ![]u8 {
    if (is_zig_0_16_or_later) {
        const io = std.testing.io;
        const file = try std.Io.Dir.openFileAbsolute(io, path, .{});
        defer file.close(io);
        var buf: [1024]u8 = undefined;
        var reader = file.reader(io, &buf);
        return try reader.interface.allocRemaining(allocator, .limited(limit));
    }
    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, limit);
}
