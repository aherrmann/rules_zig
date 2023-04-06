const std = @import("std");

extern const custom_global_symbol: u8;

test "custom_global_symbol is 42" {
    try std.testing.expectEqual(@as(u8, 42), custom_global_symbol);
}
