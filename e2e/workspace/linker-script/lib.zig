const std = @import("std");

extern const custom_global_symbol: u8;

export fn getCustomGlobalSymbol() u8 {
    return custom_global_symbol;
}
