"""Utility functions to manage semantic versions.

See https://semver.org/
"""

def _parse(version):
    """Split a semantic version into its components"""
    major, minor, patch = version.split(".", 3)
    return struct(
        major = int(major),
        minor = int(minor),
        patch = int(patch),
    )

def _sorted(versions):
    """Sort a list of strings by semantic version comparison."""

    def key(version):
        parsed = _parse(version)
        return [parsed.major, parsed.minor, parsed.patch]

    return sorted(versions, key = key)

semver = struct(
    sorted = _sorted,
)
