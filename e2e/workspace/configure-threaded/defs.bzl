"""Implements a rule to run a binary and write its output to a file."""

def _run_impl(ctx):
    ctx.actions.run_shell(
        outputs = [ctx.outputs.out],
        tools = [ctx.executable.tool],
        mnemonic = "RunBinary",
        command = "{} > {}".format(ctx.executable.tool.path, ctx.outputs.out.path),
        progress_message = "Running binary to create %{output}",
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

run = rule(
    _run_impl,
    attrs = {
        "out": attr.output(),
        "tool": attr.label(executable = True, cfg = "exec"),
    },
)
