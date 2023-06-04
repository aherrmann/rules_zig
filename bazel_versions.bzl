"""Defines the supported Bazel versions.

Used for integration tests.
"""

CURRENT_BAZEL_VERSION = "//:.bazelversion"

# TODO[AH] Deduplicate with .github/workflows/ci.yaml and MODULE.bazel
OTHER_BAZEL_VERSIONS = [
    "5.3.2",
]

SUPPORTED_BAZEL_VERSIONS = [
    CURRENT_BAZEL_VERSION,
] + OTHER_BAZEL_VERSIONS
