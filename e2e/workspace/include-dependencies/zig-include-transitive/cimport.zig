const c = @cImport({
    @cInclude("header.h");
});

pub const three: u8 = c.THREE;
