"""Implementation of the `zig_package` repository rule."""

load("@rules_zig_host_toolchain//:toolchain.bzl", "zig_path")

DOC = """\
Fetch a Zig package with the Zig SDK.

The Zig SDK downloads, verifies, and prunes the package according to its
`build.zig.zon`, and supports `git+` URLs. Fetching fails if the resulting
package hash does not match the expected `zig_hash`.
"""

ATTRS = {
    "url": attr.string(mandatory = True, doc = "The package URL, e.g. `https://...` or `git+https://...`."),
    "zig_hash": attr.string(mandatory = True, doc = "The expected Zig package hash."),
}

def _package_prefix(repository_ctx, archive):
    # The archive nests the package under `<hash>/<archive-root>/`. Strip up to
    # and including the directory that holds `build.zig.zon`.
    listing = repository_ctx.execute(["tar", "-tzf", str(archive)])
    if listing.return_code != 0:
        fail("Failed to list the Zig package archive '{}':\n{}".format(archive, listing.stderr))

    prefix = None
    for entry in listing.stdout.split("\n"):
        if entry.endswith("/build.zig.zon") and (prefix == None or len(entry) < len(prefix)):
            prefix = entry
    if prefix == None:
        fail("No `build.zig.zon` found in the Zig package archive '{}'.".format(archive))
    return prefix[:-len("/build.zig.zon")]

def _zig_package_impl(repository_ctx):
    zig = zig_path(repository_ctx)
    cache = repository_ctx.path("cache")

    fetch = repository_ctx.execute([zig, "fetch", "--global-cache-dir", str(cache), repository_ctx.attr.url])
    if fetch.return_code != 0:
        fail("`zig fetch {}` failed:\n{}".format(repository_ctx.attr.url, fetch.stderr))

    fetched_hash = fetch.stdout.strip()
    if fetched_hash != repository_ctx.attr.zig_hash:
        fail("Zig package hash mismatch for '{}':\n  expected: {}\n  fetched:  {}".format(
            repository_ctx.attr.url,
            repository_ctx.attr.zig_hash,
            fetched_hash,
        ))

    archive = cache.get_child("p").get_child(fetched_hash + ".tar.gz")
    repository_ctx.extract(archive, strip_prefix = _package_prefix(repository_ctx, archive))
    repository_ctx.delete(cache)

    repository_ctx.file("BUILD.bazel", """\
filegroup(
    name = "files",
    srcs = glob(["**"], exclude = ["BUILD.bazel"]),
    visibility = ["//visibility:public"],
)
""")

zig_package = repository_rule(
    _zig_package_impl,
    attrs = ATTRS,
    doc = DOC,
)
