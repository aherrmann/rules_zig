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
        attr = "release" if components.pre_release == None else "pre_release"
        getattr(major.setdefault(
            components.major,
            struct(release = [], pre_release = []),
        ), attr).append(version)
        getattr(minor.setdefault(
            "{}.{}".format(components.major, components.minor),
            struct(release = [], pre_release = []),
        ), attr).append(version)
        getattr(patch.setdefault(
            "{}.{}.{}".format(components.major, components.minor, components.patch),
            struct(release = [], pre_release = []),
        ), attr).append(version)

    return struct(
        major = major,
        minor = minor,
        patch = patch,
    )

def _is_valid(version):
    """Validate the formatting of a semantic version."""
    if version.count(".") < 2:
        return False

    v = _split(version)

    return all([
        v.major.isdigit(),
        v.minor.isdigit(),
        v.patch.isdigit(),
    ])

def _parse_pre_release_component(component):
    """Parse a pre-release component for sorting."""
    num = float("+Infinity")
    alpha = ""
    if component.isdigit():
        num = int(component)
    else:
        alpha = component

    return (num, alpha)

def _parse(version):
    """Split a semantic version into its components for comparison."""
    v = _split(version)

    pre_release = [v.pre_release == None]
    for component in v.pre_release or []:
        pre_release.append(_parse_pre_release_component(component))

    return struct(
        major = int(v.major),
        minor = int(v.minor),
        patch = int(v.patch),
        pre_release = pre_release,
    )

def _sorted(versions, *, reverse = False):
    """Sort a list of strings by semantic version comparison."""

    def key(version):
        parsed = _parse(version)
        return [parsed.major, parsed.minor, parsed.patch, parsed.pre_release]

    return sorted(versions, key = key, reverse = reverse)

def _is_at_least(version, minimum):
    """Compare two semantic versions for a minimum version check."""
    parsed_version = _parse(version)
    parsed_minimum = _parse(minimum)

    for attr in ["major", "minor", "patch"]:
        version_component = getattr(parsed_version, attr)
        minimum_component = getattr(parsed_minimum, attr)
        if version_component > minimum_component:
            return True
        if version_component < minimum_component:
            return False

    # A release version is greater than any pre-release of the same version.
    if parsed_version.pre_release == [True]:
        return True
    if parsed_minimum.pre_release == [True]:
        return False

    version_pre_release = parsed_version.pre_release[1:]
    minimum_pre_release = parsed_minimum.pre_release[1:]
    for i in range(min(len(version_pre_release), len(minimum_pre_release))):
        version_component = version_pre_release[i]
        minimum_component = minimum_pre_release[i]
        if version_component[0] > minimum_component[0]:
            return True
        if version_component[0] < minimum_component[0]:
            return False
        if version_component[1] > minimum_component[1]:
            return True
        if version_component[1] < minimum_component[1]:
            return False

    return len(version_pre_release) >= len(minimum_pre_release)

semver = struct(
    grouped = _grouped,
    sorted = _sorted,
    is_valid = _is_valid,
    is_at_least = _is_at_least,
)
