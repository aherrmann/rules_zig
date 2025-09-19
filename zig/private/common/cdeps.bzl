"""Handle C library dependencies."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def zig_cdeps_copts(*, compilation_context, args, transitive_inputs):
    """Computes arguments and inputs from a CcInfo.compilation_context.

    Args:
        compilation_context: cc_common.CompilationContext instance.
        args: Args; mutable, Append compiler options to this collection.
        transitive_inputs: List; mutable, Append inputs to this collection.
    """
    args.add_all(compilation_context.defines, format_each = "-D%s")
    args.add_all(compilation_context.includes, format_each = "-I%s")

    # Note, Zig does not support `-iquote` as of Zig 0.12.0
    # args.add_all(compilation_context.quote_includes, format_each = "-iquote%s")
    args.add_all(compilation_context.quote_includes, format_each = "-I%s")
    args.add_all(compilation_context.system_includes, before_each = "-isystem")
    if hasattr(compilation_context, "external_includes"):
        # Added in Bazel 7, see https://github.com/bazelbuild/bazel/commit/a6ef0b341a8ffe8ab27e5ace79d8eaae158c422b
        args.add_all(compilation_context.external_includes, before_each = "-isystem")
    args.add_all(compilation_context.framework_includes, format_each = "-F%s")

    transitive_inputs.append(compilation_context.headers)

def zig_cdeps_linker_inputs(*, linking_context, solib_parents, os, inputs, args, data):
    """Computers arguments and inputs from a CcInfo.linking_context.

    Args:
        linking_context: cc_common.LinkingContext instance.
        solib_parents: A list of strings representing the solib parent directories.
        os: String; The target operating system.
        inputs: List; mutable, Append linker inputs to this collection.
        args: Args; mutable, Append the C linker flags to this object.
        data: List; mutable, Append data files to this collection.
    """
    all_libraries = []
    dynamic_libraries = []
    for link in linking_context.linker_inputs.to_list():
        args.add_all(link.user_link_flags)
        inputs.extend(link.additional_inputs)
        for lib in link.libraries:
            file = None
            dynamic = False
            if lib.static_library != None:
                file = lib.static_library
            elif lib.pic_static_library != None:
                file = lib.pic_static_library
            elif lib.interface_library != None:
                file = lib.interface_library
                dynamic = True
            elif lib.dynamic_library != None:
                file = lib.dynamic_library
                dynamic = True

            all_libraries.append((file, dynamic))

            if dynamic and lib.dynamic_library:
                dynamic_libraries.append(lib.dynamic_library)

            # TODO[AH] Handle the remaining fields of LibraryToLink as needed:
            #   alwayslink
            #   lto_bitcode_files
            #   objects
            #   pic_lto_bitcode_files
            #   pic_objects
            #   resolved_symlink_dynamic_library
            #   resolved_symlink_interface_library

            if file:
                inputs.append(file)

    args.add_all(
        all_libraries,
        map_each = _lib_flags,
        uniquify = True,
    )
    data.extend(dynamic_libraries)
    args.add_all(
        dynamic_libraries,
        map_each = _make_to_rpath(solib_parents, os),
        allow_closure = True,
        before_each = "-rpath",
        uniquify = True,
    )

def _lib_flags(arg):
    (file, dynamic) = arg
    if dynamic:
        ext_skip = len(file.extension) + 1
        if file.basename.startswith("lib"):
            libname = file.basename[3:-ext_skip]
        else:
            libname = file.basename[:-ext_skip]
        return ["-L" + file.dirname, "-l" + libname]
    else:
        return file.path

def _make_to_rpath(solib_parents, os):
    origin = "$ORIGIN"

    # Based on `zig targets | jq .os`
    if os in ["freebsd", "ios", "macos", "netbsd", "openbsd", "tvos", "watchos"]:
        origin = "@loader_path"

    def to_rpath(lib):
        result = []
        for parent in solib_parents:
            result.append(paths.join(origin, parent, paths.dirname(lib.short_path)))
        return result

    return to_rpath
