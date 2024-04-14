"""Extensions for bzlmod."""

load("@bazel_skylib//lib:sets.bzl", "sets")
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

zig_toolchain = tag_class(attrs = {
    "zig_version": attr.string(doc = "Explicit version of Zig.", mandatory = True),
})

_TAG_CLASSES = {
    "toolchain": zig_toolchain,
}

def _toolchain_extension(module_ctx):
    versions = sets.make()
    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            sets.insert(versions, toolchain.zig_version)

    zig_register_toolchains(
        name = _DEFAULT_NAME,
        zig_versions = semver.sorted(sets.to_list(versions), reverse = True),
        register = False,
    )

zig = module_extension(
    implementation = _toolchain_extension,
    doc = _DOC,
    tag_classes = _TAG_CLASSES,
)
