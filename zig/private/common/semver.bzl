"""Utility functions to manage semantic versions.

See https://semver.org/
"""

def _split(version):
    """Split a semantic version into its components."""
    if version.find("+") != -1:
        version, _build = version.split("+", 1)

    pre_release = None
    if version.find("-") != -1:
        version, pre_release = version.split("-", 1)
        pre_release = [
            component
            for component in pre_release.split(".")
        ]

    major, minor, patch = version.split(".", 3)
    return struct(
        major = major,
        minor = minor,
        patch = patch,
        pre_release = pre_release,
    )

def _grouped(versions):
    """Group versions in a nested structure by their version components.

    Args:
      versions: sequence of string, The versions to group.

    Returns:
      `struct(major, minor, patch)`, each field has type `dict[str, dict[bool,
        list[str]]]`. The key is the grouping, e.g. `"MAJOR.MINOR"` in the
        `minor` field. The value holds all the versions fall into that group
        separated by whether they are a release version (`True`) or a
        pre-release version (`False`).
    """
    major = {}
    minor = {}
    patch = {}

    for version in versions:
        components = _split(version)
        is_release = components.pre_release == None
        major.setdefault(
            components.major,
            {True: [], False: []},
        )[is_release].append(version)
        minor.setdefault(
            "{}.{}".format(components.major, components.minor),
            {True: [], False: []},
        )[is_release].append(version)
        patch.setdefault(
            "{}.{}.{}".format(components.major, components.minor, components.patch),
            {True: [], False: []},
        )[is_release].append(version)

    return struct(
        major = major,
        minor = minor,
        patch = patch,
    )

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
