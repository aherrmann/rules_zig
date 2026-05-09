"""Test-only fake translate-c executable."""

def _fake_translate_c_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(
        output = executable,
        content = "#!/bin/sh\nexit 1\n",
        is_executable = True,
    )
    return [
        DefaultInfo(
            executable = executable,
            files = depset([executable]),
        ),
    ]

fake_translate_c = rule(
    implementation = _fake_translate_c_impl,
    executable = True,
)
