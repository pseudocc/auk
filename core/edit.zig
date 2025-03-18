const c = @import("control.zig");
const CSI = c.CSI;

pub const insert = struct {
    /// Insert Blanks (ICH)
    /// `ESC [ <n> @`
    pub fn blanks(n: u16) CSI {
        return CSI.n("@", n);
    }

    /// Insert Lines (IL)
    /// `ESC [ <n> L`
    pub fn lines(n: u16) CSI {
        return CSI.n("L", n);
    }
};

pub const delete = struct {
    /// Delete Characters (DCH)
    /// `ESC [ <n> P`
    pub fn chars(n: u16) CSI {
        return CSI.n("P", n);
    }

    /// Delete Lines (DL)
    /// `ESC [ <n> M`
    pub fn lines(n: u16) CSI {
        return CSI.n("M", n);
    }
};

pub const erase = struct {
    pub const Display = enum(u2) {
        below,
        /// Entire display
        /// Above cursor
        above,
        /// Below cursor
        both,
        /// Entire display and scrollback buffer
        all,
    };

    pub const Line = enum(u2) {
        /// Cursor to end of line
        right,
        /// Cursor to beginning of line
        left,
        /// Entire line
        both,
    };

    /// Erase Display (ED)
    /// `ESC [ <n> J`
    /// `n` is one of the `Display` variants
    pub fn display(d: Display) CSI {
        return CSI.v("J", @intFromEnum(d));
    }

    /// Erase Line (EL)
    /// `ESC [ <n> K`
    /// `n` is one of the `Line` variants
    pub fn line(l: Line) CSI {
        return CSI.v("K", @intFromEnum(l));
    }

    /// Erase Characters (ECH)
    /// `ESC [ <n> X`
    pub fn chars(n: u16) CSI {
        return CSI.n("X", n);
    }
};
