//! Represents a runfiles location path or rpath for short.

const std = @import("std");

const Self = @This();

/// The repository name component, i.e. the first component of the path.
/// This may be an apparent or a canonical repository name.
/// This may be empty for special runfiles entries, like `_repo_mapping`.
repo: []const u8,
/// The remainder of the rpath.
path: []const u8,

pub fn format(
    self: Self,
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
pub fn init(rpath: []const u8) Self {
    // TODO[AH] Consider supporting '\' separators as well.
    var iter = std.mem.splitScalar(u8, rpath, '/');
    const head = iter.first();
    const tail = iter.rest();
    return if (tail.len == 0)
        .{ .repo = "", .path = head }
    else
        .{ .repo = head, .path = tail };
}

test "RPath repo splitting" {
    {
        const input = "my_workspace/some/package/some_file";
        const expected = Self{
            .repo = "my_workspace",
            .path = "some/package/some_file",
        };
        const actual = Self.init(input);
        try std.testing.expectEqualStrings(expected.repo, actual.repo);
        try std.testing.expectEqualStrings(expected.path, actual.path);
    }

    {
        const input = "_repo_mapping";
        const expected = Self{
            .repo = "",
            .path = "_repo_mapping",
        };
        const actual = Self.init(input);
        try std.testing.expectEqualStrings(expected.repo, actual.repo);
        try std.testing.expectEqualStrings(expected.path, actual.path);
    }
}
