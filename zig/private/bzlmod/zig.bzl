"""Implementation of the `zig` module extension."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("//zig/private:platforms.bzl", "PLATFORMS")
load("//zig/private:versions.bzl", "TOOL_VERSIONS")
load("//zig/private/common:semver.bzl", "semver")
load("//zig/private/repo:toolchains_repo.bzl", "sanitize_version", "toolchains_repo")
load("//zig/private/repo:zig_repository.bzl", "zig_repository")

DOC = """\
Installs a Zig toolchain.

Every module can define multiple toolchain versions. All these versions will be
registered as toolchains and you can select the toolchain using the
`@zig_toolchains//:version` build flag.

The latest version will be the default unless the root module explicitly
declares one as the default.
"""

_DEFAULT_NAME = "zig"
DEFAULT_VERSION = TOOL_VERSIONS.keys()[0]

zig_toolchain = tag_class(attrs = {
    "zig_version": attr.string(doc = "The Zig SDK version.", mandatory = True),
    "default": attr.bool(
        doc = "Make this the default Zig SDK version. Can only be used once, and only in the root module.",
        mandatory = False,
        default = False,
    ),
})

TAG_CLASSES = {
    "toolchain": zig_toolchain,
}

def handle_tags(module_ctx):
    """Handle the zig module extension tags.

    Exposed as a standalone function for unit testing.

    Args:
      module_ctx: The module context object.

    Returns:
      (err, versions), maybe an error or the list of versions.
    """
    default = None
    versions = sets.make()

    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            if toolchain.default:
                if not mod.is_root:
                    return (["Only the root module may specify a default Zig SDK version.", toolchain], None)

                if default != None:
                    return (["You may only specify one default Zig SDK version.", toolchain], None)

                default = toolchain.zig_version

            sets.insert(versions, toolchain.zig_version)

    if default != None:
        sets.remove(versions, default)

    versions = semver.sorted(sets.to_list(versions), reverse = True)

    if default != None:
        versions.insert(0, default)

    if len(versions) == 0:
        versions.append(DEFAULT_VERSION)

    return None, versions

def _parse_zig_versions_json(json_string):
    result = {}

    data = json.decode(json_string)
    for version, platforms in data.items():
        for platform, info in platforms.items():
            result.setdefault(version, {})[platform] = struct(
                url = info["tarball"],
                sha256 = info["shasum"],
            )

    return result

def _toolchain_extension(module_ctx):
    zig_versions_json_path = module_ctx.path(Label("//zig/private:versions.json"))
    known_versions = _parse_zig_versions_json(module_ctx.read(zig_versions_json_path))

    (err, versions) = handle_tags(module_ctx)

    if err != None:
        fail(*err)

    toolchain_names = []
    toolchain_labels = []
    toolchain_zig_versions = []
    toolchain_exec_lengths = []
    toolchain_exec_constraints = []
    for zig_version in versions:
        sanitized_zig_version = sanitize_version(zig_version)
        for platform, meta in PLATFORMS.items():
            repo_name = _DEFAULT_NAME + "_" + sanitized_zig_version + "_" + platform
            toolchain_names.append(repo_name)
            toolchain_labels.append("@{}//:zig_toolchain".format(repo_name))
            toolchain_zig_versions.append(zig_version)
            toolchain_exec_lengths.append(len(meta.compatible_with))
            toolchain_exec_constraints.extend(meta.compatible_with)
            zig_repository(
                name = repo_name,
                url = known_versions[zig_version][platform].url,
                sha256 = known_versions[zig_version][platform].sha256,
                zig_version = zig_version,
                platform = platform,
            )

    toolchains_repo(
        name = _DEFAULT_NAME + "_toolchains",
        names = toolchain_names,
        labels = toolchain_labels,
        zig_versions = toolchain_zig_versions,
        exec_lengths = toolchain_exec_lengths,
        exec_constraints = toolchain_exec_constraints,
    )

zig = module_extension(
    implementation = _toolchain_extension,
    doc = DOC,
    tag_classes = TAG_CLASSES,
)
