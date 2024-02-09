//! Represents a runfiles location path or rpath for short.

const std = @import("std");

const RPath = @This();

/// The repository name component, i.e. the first component of the path.
/// This may be an apparent or a canonical repository name.
/// This may be empty for special runfiles entries, like `_repo_mapping`.
repo: []const u8,
/// The remainder of the rpath.
path: []const u8,

pub fn format(
    self: RPath,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.writeAll("rpath:");
    try writer.writeAll(self.repo);
    try writer.writeAll("//");
    try writer.writeAll(self.path);
}

/// Splits the given `rpath` into the `repo` and `path` components.
/// E.g. `my_workspace/some/package/some_file` is split into `my_workspace`
/// and `some/package/some_file`. If the `rpath` contains no `/` then the
/// `repo` component is empty and `path` takes on the full value of
/// `rpath`.
///
/// Assumes that the given `rpath` is valid, i.e. a relative path, using
/// only single forward slash (`/`) separators.
///
/// Does not take ownership of the given `rpath`.
/// Keeps a reference to the given `rpath`, i.e. the `rpath`'s lifetime
/// must be longer than that of the return `RPath`, and `rpath` should not
/// be modified during that time.
pub fn init(rpath: []const u8) RPath {
    // TODO[AH] Consider supporting '\' separators as well.
    var iter = std.mem.splitScalar(u8, rpath, '/');
    const head = iter.first();
    const tail = iter.rest();
    return if (tail.len == 0)
        .{ .repo = "", .path = head }
    else
        .{ .repo = head, .path = tail };
}

// TODO[AH] Implement OS specific behavior
//
//   See https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub
//
//   > an Rlocation(string) method that expects a runfiles-root-relative path
//   > (case-sensitive on Linux/macOS, case-insensitive on Windows) and returns
//   > the absolute path of the file, which is normalized (and lowercase on
//   > Windows) and uses "/" as directory separator on every platform (including
//   > Windows)
//
//   - Parameterize the HashMapContext by OS type (Windows, POSIX).
//   - Iterate path component wise for hash and equality.
//   - Normalize to lower-case for Windows.

pub const HashMapContext = struct {
    pub fn hash(self: @This(), p: RPath) u64 {
        _ = self;
        var hasher = std.hash.Wyhash.init(0);
        if (p.repo.len > 0) {
            hasher.update(p.repo);
            hasher.update("/");
        }
        hasher.update(p.path);
        return hasher.final();
    }
    pub fn eql(self: @This(), a: RPath, b: RPath) bool {
        _ = self;
        const eqlRepo = std.hash_map.eqlString(a.repo, b.repo);
        const eqlPath = std.hash_map.eqlString(a.path, b.path);
        return eqlRepo and eqlPath;
    }
};

test "RPath repo splitting" {
    {
        const input = "my_workspace/some/package/some_file";
        const expected = RPath{
            .repo = "my_workspace",
            .path = "some/package/some_file",
        };
        const actual = RPath.init(input);
        try std.testing.expectEqualStrings(expected.repo, actual.repo);
        try std.testing.expectEqualStrings(expected.path, actual.path);
    }

    {
        const input = "_repo_mapping";
        const expected = RPath{
            .repo = "",
            .path = "_repo_mapping",
        };
        const actual = RPath.init(input);
        try std.testing.expectEqualStrings(expected.repo, actual.repo);
        try std.testing.expectEqualStrings(expected.path, actual.path);
    }
}

test "RPath HashMapContext" {
    const ctx = HashMapContext{};
    {
        const a = RPath{ .repo = "repo", .path = "path" };
        const b = RPath{ .repo = "repo", .path = "path" };
        try std.testing.expect(ctx.hash(a) == ctx.hash(b));
        try std.testing.expect(ctx.eql(a, b));
    }

    {
        const a = RPath{ .repo = "repo_a", .path = "path" };
        const b = RPath{ .repo = "repo_b", .path = "path" };
        try std.testing.expect(ctx.hash(a) != ctx.hash(b));
        try std.testing.expect(!ctx.eql(a, b));
    }

    {
        const a = RPath{ .repo = "repo", .path = "path_a" };
        const b = RPath{ .repo = "repo", .path = "path_b" };
        try std.testing.expect(ctx.hash(a) != ctx.hash(b));
        try std.testing.expect(!ctx.eql(a, b));
    }

    {
        const a = RPath{ .repo = "foo", .path = "" };
        const b = RPath{ .repo = "", .path = "foo" };
        try std.testing.expect(ctx.hash(a) != ctx.hash(b));
        try std.testing.expect(!ctx.eql(a, b));
    }
}
