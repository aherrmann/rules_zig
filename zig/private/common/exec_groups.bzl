"""Execution groups shared by Zig rules."""

ZIG_EXEC_GROUP = "zig"
ZIG_TOOLCHAIN_TYPE = "//zig:toolchain_type"
TRANSLATE_C_TOOLCHAIN_TYPE = "//zig/translate-c:toolchain_type"

ZIG_EXEC_GROUPS = {
    ZIG_EXEC_GROUP: exec_group(toolchains = [
        ZIG_TOOLCHAIN_TYPE,
        config_common.toolchain_type(TRANSLATE_C_TOOLCHAIN_TYPE, mandatory = False),
    ]),
}

def zig_exec_group_toolchain(ctx):
    if hasattr(ctx, "exec_groups") and ZIG_EXEC_GROUP in ctx.exec_groups:
        return ctx.exec_groups[ZIG_EXEC_GROUP].toolchains[ZIG_TOOLCHAIN_TYPE].zigtoolchaininfo
    return ctx.toolchains[ZIG_TOOLCHAIN_TYPE].zigtoolchaininfo

def zig_exec_group_action_kwargs(ctx):
    kwargs = {"toolchain": ZIG_TOOLCHAIN_TYPE}
    if hasattr(ctx, "exec_groups") and ZIG_EXEC_GROUP in ctx.exec_groups:
        kwargs["exec_group"] = ZIG_EXEC_GROUP
    return kwargs

def translate_c_exec_group_toolchain(ctx):
    if hasattr(ctx, "exec_groups") and ZIG_EXEC_GROUP in ctx.exec_groups:
        return ctx.exec_groups[ZIG_EXEC_GROUP].toolchains[TRANSLATE_C_TOOLCHAIN_TYPE]
    return ctx.toolchains[TRANSLATE_C_TOOLCHAIN_TYPE]

def translate_c_exec_group_action_kwargs(ctx):
    kwargs = {"toolchain": TRANSLATE_C_TOOLCHAIN_TYPE}
    if hasattr(ctx, "exec_groups") and ZIG_EXEC_GROUP in ctx.exec_groups:
        kwargs["exec_group"] = ZIG_EXEC_GROUP
    return kwargs
