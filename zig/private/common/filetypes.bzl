"""Define filetypes accepted by rules."""

ZIG_SOURCE_EXTENSIONS = [".zig"]

# Based on the file-type classification in the Zig compiler
# https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/src/Compilation.zig#L4679-L4709
# And which of these files are treated as C sources
# https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/src/main.zig#L1349-L1354
ZIG_C_SOURCE_EXTENSIONS = [
    # .assembly
    ".s",
    ".S",
    # .c
    ".c",
    # .cpp
    ".C",
    ".cc",
    ".cpp",
    ".cxx",
    ".stub",
    # .h
    ".h",
    # .ll
    ".ll",
    # .bc
    ".bc",
    # .m
    ".m",
    # .mm
    ".mm",
    # .cu
    ".cu",
]
