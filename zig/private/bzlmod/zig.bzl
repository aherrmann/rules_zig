"""Implementation of the `zig` module extension."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("//zig/private:platforms.bzl", "PLATFORMS")
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

zig_toolchain = tag_class(
    attrs = {
        "zig_version": attr.string(doc = "The Zig SDK version.", mandatory = True),
        "default": attr.bool(
            doc = "Make this the default Zig SDK version. Can only be used once, and only in the root module.",
            mandatory = False,
            default = False,
        ),
    },
    doc = """\
Fetch and define toolchain targets for the given Zig SDK version.

Defaults to the latest known release version.
""",
)

zig_index = tag_class(
    attrs = {
        "file": attr.label(doc = "The Zig version index JSON file.", mandatory = True),
    },
    doc = """\
Extend the set of known Zig SDK versions based on a Zig version index.

The provided index must use a schema that is compatible with the [upstream index].

[upstream index]: https://ziglang.org/download/index.json
""",
)

TAG_CLASSES = {
    "toolchain": zig_toolchain,
    "index": zig_index,
}

def handle_toolchain_tags(modules, *, known_versions):
    """Handle the zig module extension's toolchain tags.

    Exposed as a standalone function for unit testing.

    Args:
      modules: sequence of module objects.
      known_versions: sequence of string, The set of known Zig versions.

    Returns:
      (err, versions), maybe an error or the list of versions.
    """
    default = None
    versions = sets.make()

    for mod in modules:
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
        versions.append(known_versions[0])

    return None, versions

def parse_zig_versions_json(json_string):
    """Parse a Zig SDK versions index in JSON format.

    Exposed as a standalone function for unit testing.

    Args:
      json_string: String, The version index in JSON format.

    Returns:
      (err, data), maybe an error or a
        `dict[version, dict[platform, struct(url, sha256)]]`.
    """
    result = {}

    data = json.decode(json_string, default = None)

    if data == None:
        return "Invalid JSON format in Zig SDK version index.", None

    for version, platforms in data.items():
        if "version" in platforms:
            version = platforms["version"]

        for platform, info in platforms.items():
            if type(info) != "dict" or not platform in PLATFORMS:
                continue

            if not "tarball" in info:
                return "Missing `tarball` field in Zig SDK version index.", None

            if not "shasum" in info:
                return "Missing `shasum` field in Zig SDK version index.", None

            result.setdefault(version, {})[platform] = struct(
                url = info["tarball"],
                sha256 = info["shasum"],
            )

    return None, result

def _merge_version_specs(version_specs):
    result = {}

    for spec in version_specs:
        for version, platforms in spec.items():
            for platform, info in platforms.items():
                result.setdefault(version, {})[platform] = info

    return result

def _toolchain_extension(module_ctx):
    version_specs = []
    for mod in module_ctx.modules:
        for index in mod.tags.index:
            file_path = module_ctx.path(index.file)
            file_content = module_ctx.read(file_path)
            (err, parsed) = parse_zig_versions_json(file_content)

            if err != None:
                fail(err, index)

            version_specs.append(parsed)

    known_versions = _merge_version_specs(version_specs)

    (err, versions) = handle_toolchain_tags(module_ctx.modules, known_versions = known_versions)

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
