"""Implementation of the zig_toolchain_header rule."""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

DOC = """\
Expose the Zig header file `zig.h` required by generated C headers.

Generates a target that can be used like a `cc_library` target.
"""

ATTRS = {
}

TOOLCHAINS = [
    "//zig:toolchain_type",
    "//zig/target:toolchain_type",
]

def max_int_alignment(arch):
    """Architecture specific maximum integer alignment.

    See https://github.com/aherrmann/zig/blob/5ad91a646a753cc3eecd8751e61cf458dadd9ac4/src/Type.zig#L1641
    """
    by_arch = {
        "avr": 1,
        "msp430": 2,
        "xcore": 4,
        "propeller": 4,
        # removed in Zig 0.14.0
        "propeller1": 4,
        "propeller2": 4,
        #
        "arm": 8,
        "armeb": 8,
        "thumb": 8,
        "thumbeb": 8,
        "hexagon": 8,
        "mips": 8,
        "mipsel": 8,
        "powerpc": 8,
        "powerpcle": 8,
        "amdgcn": 8,
        "riscv32": 8,
        "sparc": 8,
        "s390x": 8,
        "lanai": 8,
        "wasm32": 8,
        "wasm64": 8,
        #
        # For these C output format requires 16
        "powerpc64": 8,
        "powerpc64le": 8,
        "mips64": 8,
        "mips64el": 8,
        "sparc64": 8,
        #
        "x86_64": 16,
        "x86": 16,
        "aarch64": 16,
        "aarch64_be": 16,
        "riscv64": 16,
        "bpfel": 16,
        "bpfeb": 16,
        "nvptx": 16,
        "nvptx64": 16,
        #
        # Unverified according to Zig sources
        "csky": 16,
        "arc": 16,
        "m68k": 16,
        "kalimba": 16,
        "spirv": 16,
        "spirv32": 16,
        "ve": 16,
        "spirv64": 16,
        "loongarch32": 16,
        "loongarch64": 16,
        "xtensa": 16,
    }
    default = 16
    return by_arch.get(arch, default)

def _zig_toolchain_header_impl(ctx):
    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo
    zigtargetinfo = ctx.toolchains["//zig/target:toolchain_type"].zigtargetinfo

    alignment = max_int_alignment(zigtargetinfo.triple.arch)
    defines = ["ZIG_TARGET_MAX_INT_ALIGNMENT={}".format(alignment)]
    if zigtargetinfo.triple.abi == "msvc":
        defines.append("ZIG_TARGET_ABI_MSVC")

    cc_info = CcInfo(
        compilation_context = cc_common.create_compilation_context(
            headers = depset(direct = [zigtoolchaininfo.zig_c_header]),
            includes = depset(direct = [zigtoolchaininfo.zig_c_header.dirname]),
            defines = depset(direct = defines),
        ),
    )

    return [cc_info]

zig_toolchain_header = rule(
    _zig_toolchain_header_impl,
    attrs = ATTRS,
    doc = DOC,
    toolchains = TOOLCHAINS,
)
