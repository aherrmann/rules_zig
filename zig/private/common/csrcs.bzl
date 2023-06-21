"""Handle C source dependencies."""

def zig_csrcs(*, copts, csrcs, inputs, args):
    """Handle C source dependencies.

    Sets the appropriate command-line flags for the Zig compiler to include
    C source dependencies and compiler flags, if provided.

    Args:
      copts: List of String, The C compiler flags.
      csrcs: List of File, The C source files.
      inputs: List; mutable, Append the linker script inputs to this collection.
      args: Args; mutable, Append the Zig command-line flags to this object.
    """
    inputs.extend(csrcs)
    args.add_all("-cflags", copts, terminate_with = "--")
    args.add_all(csrcs)
