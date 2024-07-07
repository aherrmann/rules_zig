"""Handle C library dependencies."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def zig_cdeps(*, cdeps, solib_parents, os, direct_inputs, transitive_inputs, args, data):
    """Handle C library dependencies.

    Sets the appropriate command-line flags for the Zig compiler to expose
    provided headers and link against the provided libraries.

    Args:
      cdeps: List of Target, Must provide `CcInfo`.
      solib_parents: List of String, parent RUNPATH components in `$ORIGIN/PARENT/_solib_k8`.
      os: String, The OS component of the target triple.
      direct_inputs: List of File; mutable, Append the needed inputs to this list.
      transitive_inputs: List of depset of File; mutable, Append the needed inputs to this list.
      args: Args; mutable, Append the Zig command-line flags to this object.
      data: List of File; mutable, Append the needed runtime dependencies.
    """
    cc_info = cc_common.merge_cc_infos(direct_cc_infos = [cdep[CcInfo] for cdep in cdeps])
    _compilation_context(
        compilation_context = cc_info.compilation_context,
        inputs = transitive_inputs,
        args = args,
    )
    _linking_context(
        linking_context = cc_info.linking_context,
        solib_parents = solib_parents,
        os = os,
        inputs = direct_inputs,
        args = args,
        data = data,
    )

def _compilation_context(*, compilation_context, inputs, args):
    inputs.append(compilation_context.headers)
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

def _linking_context(*, linking_context, solib_parents, os, inputs, args, data):
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
