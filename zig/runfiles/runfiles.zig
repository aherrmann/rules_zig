//! Implements a Bazel runfiles library for rules_zig. Follows the runfiles
//! specification as of the [original design][runfiles-design], and the
//! [extended design for bzlmod support][runfiles-bzlmod].
//!
//! [runfiles-design]: https://docs.google.com/document/d/e/2PACX-1vSDIrFnFvEYhKsCMdGdD40wZRBX3m3aZ5HhVj4CtHPmiXKDCxioTUbYsDydjKtFDAzER5eg7OjJWs3V/pub
//! [runfiles-bzlmod]: https://github.com/bazelbuild/proposals/blob/53c5691c3f08011f0abf1d840d5824a3bbe039e2/designs/2022-07-21-locating-runfiles-with-bzlmod.md#2-extend-the-runfiles-libraries-to-take-repository-mappings-into-account

pub const Runfiles = @import("src/Runfiles.zig");

test {
    _ = @import("src/Directory.zig");
    _ = @import("src/discovery.zig");
    _ = @import("src/RepoMapping.zig");
    _ = @import("src/Runfiles.zig");
}
