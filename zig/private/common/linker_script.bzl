"""Handle custom linker scripts."""

def zig_linker_script(*, linker_script, inputs, args):
    """Handle custom linker scripts.

    Sets the appropriate command-line flags for the Zig compiler to configure a
    custom linker script, if provided.

    Args:
      linker_script: optional; Label, The linker script attribute.
      inputs: List; mutable, Append the linker script inputs to this collection.
      args: Args; mutable, Append the Zig command-line flags to this object.
    """

    if linker_script == None:
        return

    inputs.append(linker_script)
    args.add_all(["-T", linker_script])
