//! Implements repository mappings for bzlmod support as defined in the
//! [updated runfiles design][runfiles-bzlmod].
//!
//! [runfiles-bzlmod]: https://github.com/bazelbuild/proposals/blob/53c5691c3f08011f0abf1d840d5824a3bbe039e2/designs/2022-07-21-locating-runfiles-with-bzlmod.md#2-extend-the-runfiles-libraries-to-take-repository-mappings-into-account

const std = @import("std");
const builtin = @import("builtin");
const log = if (builtin.is_test)
    // Downgrade `err` to `warn` for tests.
    // Zig fails any test that does `log.err`, but we want to test those code paths here.
    // See https://github.com/ziglang/zig/issues/5738#issuecomment-1466902082.
    //
    // TODO[AH] Consider the diagnostic pattern instead.
    // See https://github.com/ziglang/zig/issues/2647#issuecomment-589829306
    struct {
        const base = std.log.scoped(.runfiles);
        const err = warn;
        const warn = base.warn;
        const info = base.info;
        const debug = base.debug;
    }
else
    std.log.scoped(.runfiles);

const RepoMapping = @This();

mapping: HashMapUnmanaged,
content: []const u8,

pub const InitError = ParseError || std.os.RealPathError || std.os.OpenError || std.os.PReadError;

/// Reads the given file into memory and parses the repo-mapping file format.
pub fn init(allocator: std.mem.Allocator, file_path: []const u8) InitError!RepoMapping {
    const content = std.fs.cwd().readFileAlloc(allocator, file_path, std.math.maxInt(usize)) catch |e| {
        log.err("Failed to open repository mapping ({s}) at '{s}'", .{
            @errorName(e),
            file_path,
        });
        return e;
    };
    errdefer allocator.free(content);
    var mapping = try parse(allocator, content, file_path);
    return .{
        .mapping = mapping,
        .content = content,
    };
}

pub fn deinit(self: *RepoMapping, allocator: std.mem.Allocator) void {
    self.mapping.deinit(allocator);
    allocator.free(self.content);
}

/// Performs a lookup in the parsed repo-mapping. Returns the given target
/// repository if no entry is found in the mapping but the target is a
/// canonical repository name.
pub fn lookup(self: *const RepoMapping, key: Key) ?[]const u8 {
    return self.mapping.get(key) orelse {
        const is_canonical = std.mem.indexOfScalar(u8, key.target, '~') != null;
        if (is_canonical)
            return key.target
        else
            return null;
    };
}

const ParseError = error{
    MalformedRepoMapping,
    OutOfMemory,
};

fn parse(allocator: std.mem.Allocator, content: []const u8, file_path: []const u8) ParseError!HashMapUnmanaged {
    var result: HashMapUnmanaged = .{};
    errdefer result.deinit(allocator);
    var line_count: usize = 1;
    var lines = std.mem.tokenizeAny(u8, content, "\r\n");
    while (lines.next()) |line| : (line_count += 1) {
        const err_fmt = "Missing {s} in repo mapping {s}:{d}";
        var fields = std.mem.splitScalar(u8, line, ',');
        const source = fields.first();
        const target = fields.next() orelse {
            log.err(err_fmt, .{ "target repository apparent name", file_path, line_count });
            return error.MalformedRepoMapping;
        };
        const mapping = fields.next() orelse {
            log.err(err_fmt, .{ "repository mapping", file_path, line_count });
            return error.MalformedRepoMapping;
        };
        try result.put(allocator, .{ .source = source, .target = target }, mapping);
    }
    return result;
}

test "parse empty" {
    const content = "";
    var mapping = try parse(std.testing.allocator, content, "_repo_mapping");
    defer mapping.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 0), mapping.size);
}

test "parse mappings" {
    const content =
        \\source_1,target_1,mapping_1
        \\source_2,target_2,mapping_2
        \\source_3,target_3,mapping_3
    ;
    var mapping = try parse(std.testing.allocator, content, "_repo_mapping");
    defer mapping.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 3), mapping.size);
    try std.testing.expectEqualStrings("mapping_1", mapping.get(.{ .source = "source_1", .target = "target_1" }).?);
    try std.testing.expectEqualStrings("mapping_2", mapping.get(.{ .source = "source_2", .target = "target_2" }).?);
    try std.testing.expectEqualStrings("mapping_3", mapping.get(.{ .source = "source_3", .target = "target_3" }).?);
    try std.testing.expectEqual(@as(?[]const u8, null), mapping.get(.{ .source = "source_missing", .target = "target_missing" }));
}

test "parse empty source" {
    const content = ",target,mapping";
    var mapping = try parse(std.testing.allocator, content, "_repo_mapping");
    defer mapping.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), mapping.size);
    try std.testing.expectEqualStrings("mapping", mapping.get(.{ .source = "", .target = "target" }).?);
}

test "parse empty target" {
    const content = "source,,mapping";
    var mapping = try parse(std.testing.allocator, content, "_repo_mapping");
    defer mapping.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), mapping.size);
    try std.testing.expectEqualStrings("mapping", mapping.get(.{ .source = "source", .target = "" }).?);
}

test "parse different line endings" {
    const content = "s1,t1,m1\n\ns2,t2,m2\rs3,t3,m3\r\ns4,t4,m4";
    var mapping = try parse(std.testing.allocator, content, "_repo_mapping");
    defer mapping.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 4), mapping.size);
    try std.testing.expectEqualStrings("m1", mapping.get(.{ .source = "s1", .target = "t1" }).?);
    try std.testing.expectEqualStrings("m2", mapping.get(.{ .source = "s2", .target = "t2" }).?);
    try std.testing.expectEqualStrings("m3", mapping.get(.{ .source = "s3", .target = "t3" }).?);
    try std.testing.expectEqualStrings("m4", mapping.get(.{ .source = "s4", .target = "t4" }).?);
}

test "parse missing mapping" {
    const content = "s,t";
    const result = parse(std.testing.allocator, content, "_repo_mapping");
    try std.testing.expectError(error.MalformedRepoMapping, result);
}

test "parse missing target" {
    const content = "s";
    const result = parse(std.testing.allocator, content, "_repo_mapping");
    try std.testing.expectError(error.MalformedRepoMapping, result);
}

pub const Key = struct {
    /// source repository
    source: []const u8,
    /// target repository apparent name
    target: []const u8,

    pub fn format(
        self: Key,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("({s}, {s})", .{ self.source, self.target });
    }
};

const HashMapUnmanaged = std.HashMapUnmanaged(
    Key,
    []const u8,
    Ctx,
    std.hash_map.default_max_load_percentage,
);

const Ctx = struct {
    pub fn hash(self: @This(), k: Key) u64 {
        _ = self;
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(k.source);
        hasher.update(",");
        hasher.update(k.target);
        return hasher.final();
    }
    pub fn eql(self: @This(), a: Key, b: Key) bool {
        _ = self;
        const eqlSource = std.hash_map.eqlString(a.source, b.source);
        const eqlTarget = std.hash_map.eqlString(a.target, b.target);
        return eqlSource and eqlTarget;
    }
};

test "RepoMapping init from file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile("_repo_mapping",
        \\,my_module,my_workspace
        \\,my_protobuf,protobuf~3.19.2
        \\,my_workspace,my_workspace
        \\protobuf~3.19.2,protobuf,protobuf~3.19.2
    );
    const mapping_path = try tmp.dir.realpathAlloc(std.testing.allocator, "_repo_mapping");
    defer std.testing.allocator.free(mapping_path);
    var repo_mapping = try RepoMapping.init(std.testing.allocator, mapping_path);
    defer repo_mapping.deinit(std.testing.allocator);
    try std.testing.expectEqualStrings("my_workspace", repo_mapping.mapping.get(.{ .source = "", .target = "my_module" }).?);
    try std.testing.expectEqualStrings("protobuf~3.19.2", repo_mapping.mapping.get(.{ .source = "", .target = "my_protobuf" }).?);
    try std.testing.expectEqualStrings("my_workspace", repo_mapping.mapping.get(.{ .source = "", .target = "my_workspace" }).?);
    try std.testing.expectEqualStrings("protobuf~3.19.2", repo_mapping.mapping.get(.{ .source = "protobuf~3.19.2", .target = "protobuf" }).?);
}

test "RepoMapping init missing file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const tmp_path = try tmp.dir.realpathAlloc(std.testing.allocator, ".");
    defer std.testing.allocator.free(tmp_path);
    const missing_path = try std.fs.path.join(std.testing.allocator, &[_][]const u8{
        tmp_path,
        "_repo_mapping",
    });
    defer std.testing.allocator.free(missing_path);
    const result = RepoMapping.init(std.testing.allocator, missing_path);
    try std.testing.expectError(error.FileNotFound, result);
}
