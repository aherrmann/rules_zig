"""Implementation of the zig_configure rule."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//zig/private:settings.bzl", "MODE_VALUES", "THREADED_VALUES")

DOC = """\
"""

def _zig_transition_impl(settings, attr):
    result = dict(settings)
    if attr.mode:
        result["//zig/settings:mode"] = attr.mode
    if attr.threaded:
        result["//zig/settings:threaded"] = attr.threaded
    return result

_zig_transition = transition(
    implementation = _zig_transition_impl,
    inputs = [
        "//zig/settings:mode",
        "//zig/settings:threaded",
    ],
    outputs = [
        "//zig/settings:mode",
        "//zig/settings:threaded",
    ],
)

def _make_attrs(*, executable, test):
    return {
        "actual": attr.label(
            doc = "The target to transition.",
            cfg = _zig_transition,
            executable = executable,
            mandatory = True,
        ),
        "mode": attr.string(
            doc = "The build mode setting",
            mandatory = False,
            values = MODE_VALUES,
        ),
        "threaded": attr.string(
            doc = "The threaded setting",
            mandatory = False,
            values = THREADED_VALUES,
        ),
        "_whitelist_function_transition": attr.label(
            default = "@bazel_tools//tools/whitelists/function_transition_whitelist",
        ),
    }

_FORWARD_PROVIDERS = [
]

def _make_zig_configure_rule(*, executable, test):
    _executable = executable
    _test = test

    def _zig_configure_impl(ctx):
        executable = _executable
        test = _test

        if type(ctx.attr.actual) == "list":
            if len(ctx.attr.actual) == 1:
                actual = ctx.attr.actual[0]
            else:
                fail("INTERNAL ERROR: Unexpected 1:n transition encountered.")
        else:
            actual = ctx.attr.actual

        providers = []
        for provider in _FORWARD_PROVIDERS:
            if provider in actual:
                providers.append(actual[provider])

        if executable:
            # Executable rules must create the returned executable artifact
            # themselves. This is required so that Bazel can create the
            # corresponding runfiles tree or manifest next to the produced
            # executable artifact.
            # See https://github.com/bazelbuild/bazel/issues/4170

            actual_executable = actual[DefaultInfo].files_to_run.executable
            (_, extension) = paths.split_extension(actual_executable.path)
            executable = ctx.actions.declare_file(
                ctx.label.name + extension,
            )
            ctx.actions.symlink(
                output = executable,
                target_file = actual_executable,
                is_executable = True,
            )

            # TODO[AH] Add a data attribute for executable rules.
            runfiles = ctx.runfiles(files = [executable, actual_executable])
            runfiles = runfiles.merge(actual[DefaultInfo].default_runfiles)

            providers.append(DefaultInfo(
                executable = executable,
                files = depset(direct = [executable]),
                runfiles = runfiles,
            ))
        else:
            providers.append(actual[DefaultInfo])

        return providers

    return rule(
        _zig_configure_impl,
        attrs = _make_attrs(executable = executable, test = test),
        doc = DOC,
        executable = executable,
        test = test,
    )

zig_configure = _make_zig_configure_rule(executable = False, test = False)
zig_configure_binary = _make_zig_configure_rule(executable = True, test = False)
zig_configure_test = _make_zig_configure_rule(executable = True, test = True)
