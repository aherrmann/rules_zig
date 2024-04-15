"""Extensions for bzlmod."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("//zig/private:versions.bzl", "TOOL_VERSIONS")
load("//zig/private/common:semver.bzl", "semver")
load(":repositories.bzl", "zig_register_toolchains")

_DOC = """\
Installs a Zig toolchain.
Every module can define a toolchain version under the default name, "zig".
The latest of those versions will be selected (the rest discarded),
and will always be registered by rules_zig.

Additionally, the root module can define arbitrarily many more toolchain versions
under different names (the latest version will be picked for each name)
and can register them as it sees fit,
effectively overriding the default named toolchain
due to toolchain resolution precedence.
"""

_DEFAULT_NAME = "zig"
_DEFAULT_VERSION = TOOL_VERSIONS.keys()[0]

zig_toolchain = tag_class(attrs = {
    "zig_version": attr.string(doc = "Explicit version of Zig.", mandatory = True),
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
