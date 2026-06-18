const leaf = @import("leaf");
const host = @import("host");
const top = @import("top");
const child = @import("child");
const multi = @import("multi");
const widget = @import("widget");
const greeter = @import("greeter");
const pruned = @import("pruned");
const lib = @import("lib");
const lazyhost = @import("lazyhost");
const symlinked = @import("symlinked");
const genopts = @import("genopts");
const usec = @import("usec");

pub fn main() void {
    _ = leaf.value;
    _ = host.value;
    _ = top.value;
    _ = child.value;
    _ = multi.value;
    _ = widget.value;
    _ = greeter.value;
    _ = pruned.value;
    _ = lib.v1;
    _ = lazyhost.value;
    _ = symlinked.value;
    _ = genopts.value;
    _ = usec.pid();
}
