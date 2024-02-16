//! Implements a Bazel runfiles library for rules_zig. Follows the runfiles
//! specification as of the [original design][runfiles-design], and the
//! [extended design for bzlmod support][runfiles-bzlmod].
//!
//! [runfiles-design]: https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub
//! [runfiles-bzlmod]: https://github.com/bazelbuild/proposals/blob/53c5691c3f08011f0abf1d840d5824a3bbe039e2/designs/2022-07-21-locating-runfiles-with-bzlmod.md#2-extend-the-runfiles-libraries-to-take-repository-mappings-into-account
//!
//!zig-autodoc-guide: guide.md

const std = @import("std");

pub const Runfiles = @import("src/Runfiles.zig");

test {
    _ = @import("src/Directory.zig");
    _ = @import("src/discovery.zig");
    _ = @import("src/Manifest.zig");
    _ = @import("src/RepoMapping.zig");
    _ = @import("src/RPath.zig");
    _ = @import("src/Runfiles.zig");
}

test Runfiles {
    var allocator = std.testing.allocator;

    var r = try Runfiles.create(.{ .allocator = allocator }) orelse
        return error.RunfilesNotFound;
    defer r.deinit(allocator);

    // Runfiles paths have the form `WORKSPACE/PACKAGE/FILE`.
    // Use `$(rlocationpath ...)` expansion in your `BUILD.bazel` file to
    // obtain one. You can forward it to your executable using the `env` or
    // `args` attribute, or by embedding it in a generated file.
    const rpath = "rules_zig/zig/runfiles/test-data.txt";
    // Runfiles lookup is subject to repository remapping. You must pass the
    // name of the repository relative to which the runfiles path is valid.
    // Use the auto-generated `bazel_builtin` module to obtain it.
    const source = @import("bazel_builtin").current_repository;

    const allocated_path = try r.rlocationAlloc(allocator, rpath, source) orelse
        // Runfiles path lookup may return `null`.
        return error.RPathNotFound;
    defer allocator.free(allocated_path);

    const file = std.fs.openFileAbsolute(allocated_path, .{}) catch |e| switch (e) {
        error.FileNotFound => {
            // Runfiles path lookup may return a non-existent path.
            return error.RPathNotFound;
        },
        else => |e_| return e_,
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
