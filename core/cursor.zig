const c = @import("control.zig");
const CSI = c.CSI;
const ESC = c.ESC;

/// Cursor Up (CUU)
/// `ESC [ <n> A`
pub fn up(n: u16) CSI {
    return CSI.n("A", n);
}

/// Cursor Down (CUD)
/// `ESC [ <n> B`
pub fn down(n: u16) CSI {
    return CSI.n("B", n);
}

/// Cursor Forward (CUF)
/// `ESC [ <n> C`
pub fn right(n: u16) CSI {
    return CSI.n("C", n);
}

/// Cursor Backward (CUB)
/// `ESC [ <n> D`
pub fn left(n: u16) CSI {
    return CSI.n("D", n);
}

/// Cursor Next Line (CNL)
/// `ESC [ <n> E`
pub fn next(n: u16) ESC {
    return CSI.n("E", n);
}

/// Cursor Previous Line (CPL)
/// `ESC [ <n> F`
pub fn prev(n: u16) ESC {
    return CSI.n("F", n);
}

/// Cursor Position (CUP)
/// `ESC [ <y> ; <x> H` when x and y are both non-zero
/// `ESC [ <x> G` when y is zero
/// `ESC [ <y> d` when x is zero
pub fn goto(x: u16, y: u16) CSI {
    return if (x == 0)
        row(y)
    else if (y == 0)
        col(x)
    else
        CSI{
            .command = "H",
            .params = CSI.Params.two(y, x),
        };
}

/// Cursor Horizontal Position Absolute (HPA)
/// `ESC [ <x> G`
pub fn col(x: u16) CSI {
    return CSI.n("G", x);
}

/// Cursor Vertical Position Absolute (VPA)
/// `ESC [ <y> d`
pub fn row(y: u16) CSI {
    return CSI.n("d", y);
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
pub const position = CSI.n("n", 6);

pub const scroll = struct {
    /// Scroll Up (SU)
    /// `ESC [ <n> S`
    pub fn up(n: u16) CSI {
        return CSI.n("S", n);
    }

    /// Scroll Down (SD)
    /// `ESC [ <n> T`
    pub fn down(n: u16) CSI {
        return CSI.n("T", n);
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

/// Cursor Horizontal Tabulation (CBT / CHT)
/// `ESC [ <n> I` when n is positive
/// `ESC [ <n> Z` when n is negative
pub fn tab(n: i16) CSI {
    return if (n < 0)
        CSI.n("Z", @intCast(-n))
    else
        CSI.n("I", @intCast(n));
}
