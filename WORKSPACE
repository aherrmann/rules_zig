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

# TODO[AH] Zig version
zig_register_toolchains(
    name = "zig1_14",
    zig_version = "1.14.2",
)

# For running our own unit tests
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.19.3")

gazelle_dependencies()
