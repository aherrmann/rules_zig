"""Generate the `bazel_builtin` module."""

load("//zig/private/providers:zig_module_info.bzl", "ZigModuleInfo")

ATTRS = {
    "_bazel_builtin_template": attr.label(
        allow_single_file = True,
        default = Label("//zig/private/common:bazel_builtin.zig.tpl"),
    ),
}

def bazel_builtin_module(ctx):
    """Generate a `bazel_builtin` module for the current target.

    Args:
      ctx: Bazel rule context object.

    Returns:
      ZigModuleInfo provider.
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

    substitutions = ctx.actions.template_dict()
    substitutions.add("{current_repository}", repo_name)
    substitutions.add("{current_package}", package_name)
    substitutions.add("{current_target}", target_name)

    ctx.actions.expand_template(
        template = ctx.file._bazel_builtin_template,
        output = main,
        computed_substitutions = substitutions,
        is_executable = False,
    )

    module = ZigModuleInfo(
        name = "bazel_builtin",
        canonical_name = name,
        main = main,
        srcs = [],
        all_mods = depset(direct = ["{name}::{src}".format(
            name = name,
            src = main.path,
        )]),
        all_srcs = depset(direct = [main]),
    )

    return module
