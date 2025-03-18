const std = @import("std");
const builtin = @import("builtin");
const manifest = @import("auk.manifest");
const c = @import("control.zig");
const CSI = c.CSI;
const ESC = c.ESC;

/// Full Reset (RIS)
/// `ESC c`
pub const reset = ESC{ .command = "c" };

/// Insert Mode (IRM)
/// `ESC [ 4 h` or `ESC [ 4 l`
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

pub const cursor = @import("cursor.zig");

// usingnamespace is about to be deprecated, so not using it here
const edit = @import("edit.zig");
pub const insert = edit.insert;
pub const delete = edit.delete;
pub const erase = edit.erase;

pub const SGR = @import("sgr.zig");

pub const version = manifest.version;

pub const description = std.fmt.comptimePrint(
    "🌊AUK🐦 {} ({s}-{s}-{s} {s}) [ZIG {}]",
    .{
        version,
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
        @tagName(builtin.abi),
        @tagName(builtin.mode),
        builtin.zig_version,
    },
);
