"""Handle C library dependencies."""

def zig_cdeps(*, cdeps, direct_inputs, transitive_inputs, args):
    """Handle C library dependencies.

    Sets the appropriate command-line flags for the Zig compiler to expose
    provided headers and link against the provided libraries.

    Args:
      cdeps: List of Target, Must provide `CcInfo`.
      direct_inputs: List of File; mutable, Append the needed inputs to this list.
      transitive_inputs: List of depset of File; mutable, Append the needed inputs to this list.
      args: Args; mutable, Append the Zig command-line flags to this object.
    """
    cc_info = cc_common.merge_cc_infos(direct_cc_infos = [cdep[CcInfo] for cdep in cdeps])
    _compilation_context(
        compilation_context = cc_info.compilation_context,
        inputs = transitive_inputs,
        args = args,
    )
    _linking_context(
        linking_context = cc_info.linking_context,
        inputs = direct_inputs,
        args = args,
    )

def _compilation_context(*, compilation_context, inputs, args):
    inputs.append(compilation_context.headers)
    args.add_all(compilation_context.defines, format_each = "-d%s")
    args.add_all(compilation_context.includes, format_each = "-I%s")

    # Note, Zig does not support `-iquote` as of Zig 0.11.0
    # args.add_all(compilation_context.quote_includes, format_each = "-iquote%s")
    args.add_all(compilation_context.quote_includes, format_each = "-I%s")
    args.add_all(compilation_context.system_includes, format_each = "-isystem%s")
    args.add_all(compilation_context.external_includes, format_each = "-isystem%s")
    args.add_all(compilation_context.framework_includes, format_each = "-F%s")

def _linking_context(*, linking_context, inputs, args):
    for link in linking_context.linker_inputs.to_list():
        args.add_all(link.user_link_flags)
        inputs.extend(link.additional_inputs)
        for lib in link.libraries:
            file = None
            if lib.static_library != None:
                file = lib.static_library
            elif lib.pic_static_library != None:
                file = lib.pic_static_library
            elif lib.interface_library != None:
                file = lib.interface_library
            elif lib.dynamic_library != None:
                file = lib.dynamic_library

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
