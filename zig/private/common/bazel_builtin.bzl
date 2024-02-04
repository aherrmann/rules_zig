"""Generate the `bazel_builtin` package."""

load("//zig/private/providers:zig_package_info.bzl", "ZigPackageInfo")

def bazel_builtin_package(ctx):
    """Generate a `bazel_builtin` package for the current target.

    Args:
      ctx: Bazel rule context object.

    Returns:
      ZigPackageInfo provider.
    """
    repo_name = ctx.label.repo_name if hasattr(ctx.label, "repo_name") else ctx.label.workspace_name
    package_name = ctx.label.package
    target_name = ctx.label.name

    name = "bazel_builtin_A{repo}_S_S{package}_C{target}".format(
        repo = repo_name.replace("~", "_T"),
        package = package_name.replace("/", "_S"),
        target = target_name,
    )
    main = ctx.actions.declare_file(name + ".zig")

    # TODO[AH] Use ctx.actions.template_dict and ctx.actions.expand_template.
    content = """\
pub const current_repository: []const u8 = "{repo}";
pub const current_package: []const u8 = "{package}";
pub const current_target: []const u8 = "{target}";
""".format(
        repo = repo_name,
        package = package_name,
        target = target_name,
    )
    ctx.actions.write(main, content, is_executable = False)

    package = ZigPackageInfo(
        name = name,
        main = main,
        srcs = [],
        flags = ["--pkg-begin", name, main.path, "--pkg-end"],
        all_mods = depset(direct = ["{name}::{src}".format(
            name = name,
            src = main.path,
        )]),
        all_srcs = depset(direct = [main]),
    )

    return package
