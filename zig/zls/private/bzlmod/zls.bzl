"""Implementation of the `zls` module extension."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("//zig/private:platforms.bzl", "PLATFORMS")
load("//zig/zls/private/repo:toolchains_repo.bzl", "sanitize_version", "toolchains_repo")
load("//zig/zls/private/repo:zls_repository.bzl", "zls_repository")

DOC = """\
Installs ZLS toolchains.

Each ZLS toolchain is explicitly tied to a Zig SDK version. The Zig SDK version
is only used for toolchain selection through @zig_toolchains//:version; it does
not need to match the ZLS artifact version.
"""

_DEFAULT_NAME = "zls"

zls_toolchain = tag_class(
    attrs = {
        "zig_version": attr.string(
            doc = "The Zig SDK version that selects this ZLS toolchain.",
            mandatory = True,
        ),
        "zls_version": attr.string(
            doc = "The ZLS artifact version to download.",
            mandatory = True,
        ),
    },
    doc = """\
Fetch and define ZLS toolchain targets for the given ZLS artifact version, gated
by the given Zig SDK version.
""",
)

zls_index = tag_class(
    attrs = {
        "file": attr.label(doc = "The ZLS version index JSON file.", mandatory = True),
    },
    doc = """\
Extend the set of known ZLS versions based on a ZLS version index.
""",
)

zls_mirrors = tag_class(
    attrs = {
        "urls": attr.string_list(doc = "The mirrors base URLs.", mandatory = True),
    },
)

TAG_CLASSES = {
    "toolchain": zls_toolchain,
    "index": zls_index,
    "mirrors": zls_mirrors,
}

def parse_zls_versions_json(json_string):
    """Parse a ZLS versions index in JSON format.

    Args:
      json_string: String, The version index in JSON format.

    Returns:
      (err, data), maybe an error or a
        `dict[version, dict[platform, struct(url, sha256)]]`.
    """
    result = {}

    data = json.decode(json_string, default = None)
    if data == None:
        return "Invalid JSON format in ZLS version index.", None

    for version, platforms in data.items():
        if type(platforms) != "dict":
            continue

        for platform, info in platforms.items():
            if type(info) != "dict" or not platform in PLATFORMS:
                continue

            if not "tarball" in info:
                return "Missing `tarball` field in ZLS version index.", None

            if not "shasum" in info:
                return "Missing `shasum` field in ZLS version index.", None

            result.setdefault(version, {})[platform] = struct(
                url = info["tarball"],
                sha256 = info["shasum"],
            )

    return None, result

def merge_version_specs(version_specs):
    """Merge ZLS version indices.

    Args:
      version_specs: sequence of `dict[version, dict[platform, struct(url, sha256)]]`.

    Returns:
      `dict[version, dict[platform, struct(url, sha256)]]`
    """
    result = {}

    for spec in version_specs:
        for version, platforms in spec.items():
            for platform, info in platforms.items():
                result.setdefault(version, {})[platform] = info

    return result

def handle_toolchain_tags(modules):
    """Handle the zls module extension's toolchain tags.

    Args:
      modules: sequence of module objects.

    Returns:
      (err, mappings), maybe an error or a list of
        `struct(zig_version, zls_version)` mappings.
    """
    seen_zig_versions = sets.make()
    mappings = []

    for mod in modules:
        for toolchain in mod.tags.toolchain:
            if sets.contains(seen_zig_versions, toolchain.zig_version):
                return (["You may only specify one ZLS toolchain for Zig SDK version '{}'.".format(toolchain.zig_version), toolchain], None)

            sets.insert(seen_zig_versions, toolchain.zig_version)
            mappings.append(struct(
                zig_version = toolchain.zig_version,
                zls_version = toolchain.zls_version,
            ))

    return None, mappings

def _toolchain_extension(module_ctx):
    mirrors = []
    version_specs = []
    for mod in module_ctx.modules:
        for mirrors_tag in mod.tags.mirrors:
            mirrors.extend(mirrors_tag.urls)
        for index in mod.tags.index:
            file_path = module_ctx.path(index.file)
            file_content = module_ctx.read(file_path)
            (err, parsed) = parse_zls_versions_json(file_content)

            if err != None:
                fail(err, index)

            version_specs.append(parsed)

    known_versions = merge_version_specs(version_specs)

    (err, mappings) = handle_toolchain_tags(module_ctx.modules)
    if err != None:
        fail(*err)

    toolchain_names = []
    toolchain_labels = []
    toolchain_zig_versions = []
    toolchain_exec_lengths = []
    toolchain_exec_constraints = []
    created_repos = sets.make()
    for mapping in mappings:
        if mapping.zls_version not in known_versions:
            fail("Unknown ZLS version '{}'. Add it to zls.index or choose a known version.".format(mapping.zls_version))

        sanitized_zls_version = sanitize_version(mapping.zls_version)
        for platform, meta in PLATFORMS.items():
            if platform not in known_versions[mapping.zls_version]:
                continue

            repo_name = _DEFAULT_NAME + "_" + sanitized_zls_version + "_" + platform
            toolchain_names.append("{}_for_{}_{}".format(
                sanitized_zls_version,
                sanitize_version(mapping.zig_version),
                platform,
            ))
            toolchain_labels.append("@{}//:zls_toolchain".format(repo_name))
            toolchain_zig_versions.append(mapping.zig_version)
            toolchain_exec_lengths.append(len(meta.compatible_with))
            toolchain_exec_constraints.extend(meta.compatible_with)
            if not sets.contains(created_repos, repo_name):
                sets.insert(created_repos, repo_name)
                zls_repository(
                    name = repo_name,
                    url = known_versions[mapping.zls_version][platform].url,
                    mirrors = mirrors,
                    sha256 = known_versions[mapping.zls_version][platform].sha256,
                    zls_version = mapping.zls_version,
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

zls = module_extension(
    implementation = _toolchain_extension,
    doc = DOC,
    tag_classes = TAG_CLASSES,
)
