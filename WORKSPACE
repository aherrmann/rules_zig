# Declare the local Bazel workspace.
workspace(
    name = "rules_zig",
)

load(":internal_deps.bzl", "rules_zig_internal_deps")

# Fetch deps needed only locally for development
rules_zig_internal_deps()

load("//zig:repositories.bzl", "rules_zig_dependencies", "zig_register_toolchains")

# Fetch dependencies which users need as well
rules_zig_dependencies()

# Use the latest known Zig SDK version for testing
# buildifier: disable=bzl-visibility
load("//zig/private:versions.bzl", "TOOL_VERSIONS")

zig_register_toolchains(
    name = "zig",
    zig_version = TOOL_VERSIONS.keys()[0],
)

# rules_python dependencies
load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()

# For running our own unit tests
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

# For buildifier linting
load("@buildifier_prebuilt//:deps.bzl", "buildifier_prebuilt_deps")

buildifier_prebuilt_deps()

load("@buildifier_prebuilt//:defs.bzl", "buildifier_prebuilt_register_toolchains")

buildifier_prebuilt_register_toolchains()

# For running integration tests
load("@rules_bazel_integration_test//bazel_integration_test:deps.bzl", "bazel_integration_test_rules_dependencies")

bazel_integration_test_rules_dependencies()

load("@cgrindel_bazel_starlib//:deps.bzl", "bazel_starlib_dependencies")

bazel_starlib_dependencies()

load("@rules_bazel_integration_test//bazel_integration_test:defs.bzl", "bazel_binaries")

bazel_binaries(versions = [
    "//:.bazelversion",
    "5.3.2",
])

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.19.3")

gazelle_dependencies()

load("@bazel_skylib_gazelle_plugin//:workspace.bzl", "bazel_skylib_gazelle_plugin_workspace")

bazel_skylib_gazelle_plugin_workspace()
