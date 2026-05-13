"""Rules to declare ZLS toolchains."""

ZlsToolchainInfo = provider(
    doc = "Information about how to invoke a ZLS executable.",
    fields = {
        "bin": "File, The ZLS executable.",
        "files_to_run": "FilesToRunProvider, The ZLS executable and its runfiles.",
        "zls_version": "String, The ZLS version.",
    },
)

def _zls_toolchain_impl(ctx):
    bin = ctx.executable.bin
    default = DefaultInfo(
        files = depset([bin]),
        runfiles = ctx.runfiles(files = [bin]),
    )
    zlstoolchaininfo = ZlsToolchainInfo(
        bin = bin,
        files_to_run = ctx.attr.bin[DefaultInfo].files_to_run,
        zls_version = ctx.attr.zls_version,
    )
    toolchain_info = platform_common.ToolchainInfo(
        default = default,
        zlstoolchaininfo = zlstoolchaininfo,
    )

    return [
        default,
        zlstoolchaininfo,
        toolchain_info,
    ]

zls_toolchain = rule(
    implementation = _zls_toolchain_impl,
    attrs = {
        "bin": attr.label(
            doc = "The ZLS executable target or prebuilt executable file.",
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "zls_version": attr.string(
            doc = "The ZLS version.",
            mandatory = True,
        ),
    },
    doc = "Defines a ZLS toolchain.",
)
