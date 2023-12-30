"""Handle C library dependencies."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def zig_cdeps(*, cdeps, output_dir, direct_inputs, transitive_inputs, args, data):
    """Handle C library dependencies.

    Sets the appropriate command-line flags for the Zig compiler to expose
    provided headers and link against the provided libraries.

    Args:
      cdeps: List of Target, Must provide `CcInfo`.
      output_dir: String, The directory in which the binary or library is created. Used for RUNPATH calcuation.
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
        output_dir = output_dir,
        inputs = direct_inputs,
        args = args,
        data = data,
    )

def _compilation_context(*, compilation_context, inputs, args):
    inputs.append(compilation_context.headers)
    args.add_all(compilation_context.defines, format_each = "-D%s")
    args.add_all(compilation_context.includes, format_each = "-I%s")

    # Note, Zig does not support `-iquote` as of Zig 0.11.0
    # args.add_all(compilation_context.quote_includes, format_each = "-iquote%s")
    args.add_all(compilation_context.quote_includes, format_each = "-I%s")
    args.add_all(compilation_context.system_includes, before_each = "-isystem")
    if hasattr(compilation_context, "external_includes"):
        # Added in Bazel 7, see https://github.com/bazelbuild/bazel/commit/a6ef0b341a8ffe8ab27e5ace79d8eaae158c422b
        args.add_all(compilation_context.external_includes, before_each = "-isystem")
    args.add_all(compilation_context.framework_includes, format_each = "-F%s")

def _linking_context(*, linking_context, output_dir, inputs, args, data):
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
                args.add(file)

    args.add_all(dynamic_libraries, map_each = _make_to_rpath(output_dir), allow_closure = True, before_each = "-rpath")
    data.extend(dynamic_libraries)

def _make_to_rpath(output_dir):
    def to_rpath(lib):
        result = paths.join("$ORIGIN", _relativize(lib.dirname, output_dir))
        return result

    return to_rpath

def _relativize(path, start):
    """Generates a path to `path` relative to `start`.

    Strips any common prefix, generates up-directory references corresponding
    to the depth of the remainder of `start`, and appends the remainder of
    `path`.

    Note, Bazel Skylib's `paths.relativize` does not generate up-directory
    references.

    Args:
      path: String, The target path.
      start: String, The starting point.

    Returns:
      String, A relative path.
    """
    path_segments = path.split("/")
    start_segments = start.split("/")

    common = 0
    for path_segment, start_segment in zip(path_segments, start_segments):
        if path_segment != start_segment:
            break

        common += 1

    up_count = len(start_segments) - common

    result_segments = [".."] * up_count + path_segments[common:]
    result = paths.join(*result_segments)

    return result
