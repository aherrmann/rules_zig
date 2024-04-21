"""Implementation of the `zig` module extension."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("//zig:repositories.bzl", "zig_register_toolchains")
load("//zig/private:versions.bzl", "TOOL_VERSIONS")
load("//zig/private/common:semver.bzl", "semver")

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
                    return (("Only the root module may specify a default Zig SDK version.", toolchain), None)

                if default != None:
                    return (("You may only specify one default Zig SDK version.", toolchain), None)

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

def _toolchain_extension(module_ctx):
    (err, versions) = handle_tags(module_ctx)

    if err != None:
        fail(*err)

    zig_register_toolchains(
        name = _DEFAULT_NAME,
        zig_versions = versions,
        register = False,
    )

zig = module_extension(
    implementation = _toolchain_extension,
    doc = DOC,
    tag_classes = TAG_CLASSES,
)
