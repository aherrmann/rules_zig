"""Utility functions to manage semantic versions.

See https://semver.org/
"""

def _parse_pre_release_component(component):
    """Parse a pre-release component for sorting."""
    num = float("+Infinity")
    alpha = ""
    if component.isdigit():
        num = int(component)
    else:
        alpha = component

    return (False, num, alpha)

def _parse(version):
    """Split a semantic version into its components for comparison."""
    if version.find("+") != -1:
        version, _build = version.split("+", 1)

    pre_release = [(True, 0, "")]
    if version.find("-") != -1:
        version, pre_release = version.split("-", 1)
        pre_release = [
            _parse_pre_release_component(component)
            for component in pre_release.split(".")
        ]

    major, minor, patch = version.split(".", 3)
    return struct(
        major = int(major),
        minor = int(minor),
        patch = int(patch),
        pre_release = pre_release,
    )

# buildifier: disable=unused-variable
def _grouped(versions):
    """Group versions in a nested structure by their version components.

    Args:
      versions: sequence of string, The versions to group.

    Returns:
      `struct(major, minor, patch, pre_release)`, each field is a `dict` from
        string to list of string, where the key is the grouping, e.g.
        `"MAJOR.MINOR"` in the `minor` field, and the value is the list of
        versions that fall into this group.
    """
    pass

def _sorted(versions, *, reverse = False):
    """Sort a list of strings by semantic version comparison."""

    def key(version):
        parsed = _parse(version)
        return [parsed.major, parsed.minor, parsed.patch, parsed.pre_release]

    return sorted(versions, key = key, reverse = reverse)

semver = struct(
    grouped = _grouped,
    sorted = _sorted,
)
