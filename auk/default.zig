const c = @import("control.zig");
const CSI = c.CSI;

/// Insert Mode (IRM)
/// `ESC [ 4 h` or `ESC [ 4 l`
/// default: replace
pub const input = struct {
    const toggle = CSI.Switch.init(4, false);
    pub const insert = toggle.on;
    pub const replace = toggle.off;
};

/// Auto Wrap Mode (DECAWM)
/// `ESC [ ? 7 h` or `ESC [ ? 7 l`
pub const wrap = CSI.Switch.init(7, true);

/// Alternate Screen Buffer (ALTBUF) With Cursor Save and Clear on Enter
/// `ESC [ ? 1049 h` or `ESC [ ? 1049 l`
/// Note: some terminals will not move the cursor to the top left corner.
pub const altbuf = CSI.Switch.init(1049, true);

/// Mouse Tracking with Movement
/// `ESC [ ? 1003 h` or `ESC [ ? 1003 l`
pub const mouse = struct {
    const toggle = CSI.Switch.init(1003, true);
    pub const track = toggle.on;
    pub const untrack = toggle.off;
};

pub fn hello(writer: anytype) !void {
    try writer.print("🌊🐦\n", .{});
}
