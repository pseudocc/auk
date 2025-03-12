const c = @import("control.zig");
const CSI = c.CSI;
const ESC = c.ESC;

/// Cursor Up (CUU)
/// `ESC [ <n> A`
pub fn up(n: u16) CSI {
    return CSI{ .command = "A", .params = CSI.Params.one(n) };
}

/// Cursor Down (CUD)
/// `ESC [ <n> B`
pub fn down(n: u16) CSI {
    return CSI{ .command = "B", .params = CSI.Params.one(n) };
}

/// Cursor Forward (CUF)
/// `ESC [ <n> C`
pub fn right(n: u16) CSI {
    return CSI{ .command = "C", .params = CSI.Params.one(n) };
}

/// Cursor Backward (CUB)
/// `ESC [ <n> D`
pub fn left(n: u16) CSI {
    return CSI{ .command = "D", .params = CSI.Params.one(n) };
}

/// Cursor Next Line (CNL)
/// `ESC [ <n> E`
pub fn next(n: u16) ESC {
    return ESC{ .command = "E", .n = n };
}

/// Cursor Previous Line (CPL)
/// `ESC [ <n> F`
pub fn prev(n: u16) ESC {
    return ESC{ .command = "F", .n = n };
}

/// Cursor Position (CUP)
/// `ESC [ <y> ; <x> H`
pub fn goto(x: u16, y: u16) CSI {
    return CSI{ .command = "H", .params = CSI.Params.two(y, x) };
}

/// Cursor Horizontal Position Absolute (HPA)
/// `ESC [ <x> G`
pub fn col(x: u16) CSI {
    return CSI{ .command = "G", .params = CSI.Params.one(x) };
}

/// Cursor Vertical Position Absolute (VPA)
/// `ESC [ <y> d`
pub fn row(y: u16) CSI {
    return CSI{ .command = "d", .params = CSI.Params.one(y) };
}

/// Save Cursor (DECSC)
/// `ESC 7`
pub const save = ESC{ .command = "7" };

/// Restore Cursor (DECRC)
/// `ESC 8`
pub const restore = ESC{ .command = "8" };

const visible = CSI.Toggle.init(25, true);

/// Cursor Visibility (DECTCEM)
/// `ESC [ ? 25 h`
pub const show = visible.on;

/// Cursor Visibility (DECTCEM)
/// `ESC [ ? 25 l`
pub const hide = visible.off;

/// Report Cursor Position (CPR)
/// `ESC [ 6 n`
pub const position = CSI{ .command = "n", .params = CSI.Params.one(6) };

pub const scroll = struct {
    /// Scroll Up (SU)
    /// `ESC [ <n> S`
    pub fn up(n: u16) CSI {
        return CSI{ .command = "S", .params = CSI.Params.one(n) };
    }

    /// Scroll Down (SD)
    /// `ESC [ <n> T`
    pub fn down(n: u16) CSI {
        return CSI{ .command = "T", .params = CSI.Params.one(n) };
    }
};

/// Cursor Style (DECSCUSR)
/// `ESC <p> SP q`
pub const style = struct {
    fn inner(n: ?u8) ESC {
        return ESC{ .command = " q", .n = n };
    }

    pub const default = inner(null);

    const Highlight = enum {
        blink,
        steady,
    };

    pub fn block(hl: Highlight) ESC {
        return inner(1 + @intFromEnum(hl));
    }

    pub fn underline(hl: Highlight) ESC {
        return inner(3 + @intFromEnum(hl));
    }

    pub fn bar(hl: Highlight) ESC {
        return inner(5 + @intFromEnum(hl));
    }
};

/// Index (IND)
/// `ESC D`
pub const index = ESC{ .command = "D" };

/// Reverse Index (RI)
/// `ESC M`
pub const rindex = ESC{ .command = "M" };
