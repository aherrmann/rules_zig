"""Implementation of the `zig` module extension."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("//zig/private:versions.bzl", "TOOL_VERSIONS")
load("//zig/private/common:semver.bzl", "semver")
load("//zig:repositories.bzl", "zig_register_toolchains")

_DOC = """\
Installs a Zig toolchain.

Every module can define multiple toolchain versions. All these versions will be
registered as toolchains and you can select the toolchain using the
`@zig_toolchains//:version` build flag.

The latest version will be the default unless the root module explicitly
declares one as the default.
"""

_DEFAULT_NAME = "zig"
_DEFAULT_VERSION = TOOL_VERSIONS.keys()[0]

zig_toolchain = tag_class(attrs = {
    "zig_version": attr.string(doc = "The Zig SDK version.", mandatory = True),
    "default": attr.bool(
        doc = "Make this the default Zig SDK version. Can only be used once, and only in the root module.",
        mandatory = False,
        default = False,
    ),
})

_TAG_CLASSES = {
    "toolchain": zig_toolchain,
}

def _toolchain_extension(module_ctx):
    default = None
    versions = sets.make()
    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            if toolchain.default:
                if not mod.is_root:
                    fail("Only the root module may specify a default Zig SDK version.", toolchain)
                elif default != None:
                    fail("You may only specify one default Zig SDK version.", toolchain)
                else:
                    default = toolchain.zig_version
            else:
                sets.insert(versions, toolchain.zig_version)

    versions = semver.sorted(sets.to_list(versions), reverse = True)
    if default != None:
        versions.insert(0, default)
    elif len(versions) == 0:
        versions.append(_DEFAULT_VERSION)

    zig_register_toolchains(
        name = _DEFAULT_NAME,
        zig_versions = versions,
        register = False,
    )

zig = module_extension(
    implementation = _toolchain_extension,
    doc = _DOC,
    tag_classes = _TAG_CLASSES,
)
