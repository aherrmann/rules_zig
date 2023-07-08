"""Handle runtime data dependencies."""

def zig_collect_data(*, data, deps, transitive_data, transitive_runfiles):
    """Handle data dependencies.

    Collects runtime data from the given dependencies.
    Data dependency attributes will contribute both,
    their output files and their own runtime data dependencies.
    Other dependency attributes will only contribute
    their own runtime data dependencies.

    Args:
      data: List of Target, Data dependency attributes.
      deps: List of Target, Other dependency attributes.
      transitive_data: List of depset of File; mutable, Append data file dependencies.
      transitive_runfiles: List of runfiles; mutable, Append runfile dependencies.
    """
    for data in data:
        transitive_data.append(data[DefaultInfo].files)
        transitive_runfiles.append(data[DefaultInfo].default_runfiles)

    for dep in deps:
        transitive_runfiles.append(dep[DefaultInfo].default_runfiles)

def zig_create_runfiles(*, ctx_runfiles, direct_data, transitive_data, transitive_runfiles):
    """Create a new runfiles object.

    The newly created runfiles will bundle all provided data files and runfiles.

    Args:
      ctx_runfiles: Runfiles constructor function.
      direct_data: List of File, Data files.
      transitive_data: List of depset of File, Data files.
      transitive_runfiles: List of depset of File, Runfiles.
    """
    return ctx_runfiles(
        files = direct_data,
        transitive_files = depset(transitive = transitive_data),
    ).merge_all(transitive_runfiles)
