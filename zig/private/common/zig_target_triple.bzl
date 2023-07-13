"""Helper module to parse and generate Zig (LLVM) target triples."""

def _make_triple(*, arch = None, os = None, abi = None):
    """Create a Zig target triple.

    Args:
      arch: optional String, the architecture.
      os: optional String, the operating system.
      abi: optional String, the application binary interface.

    Returns:
      struct(arch, os, abi), representing the triple.
    """
    return struct(
        arch = arch,
        os = os,
        abi = abi,
    )

def _to_string(triple):
    """Convert a triple to its string representation.

    Args:
      triple: struct, representing the triple.

    Returns:
      String, representing the triple.
    """
    return "-".join([
        component
        for component in [triple.arch, triple.os, triple.abi]
        if component != None
    ])

def _from_string(s):
    """Parse a triple from a string.

    Args:
      s: String, the string to parse.

    Returns:
      struct, representing the triple.
    """
    component_names = ["arch", "os", "abi"]
    component_values = s.split("-")
    components = dict(zip(component_names, component_values))
    return _make_triple(**components)

triple = struct(
    make = _make_triple,
    to_string = _to_string,
    from_string = _from_string,
)
