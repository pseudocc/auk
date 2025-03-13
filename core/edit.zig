const c = @import("control.zig");
const CSI = c.CSI;
const ESC = c.ESC;

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
    pub const Display = enum {
        /// Above cursor
        above,
        /// Below cursor
        below,
        /// Entire display
        both,
        /// Entire display and scrollback buffer
        all,
    };

    pub const Line = enum {
        /// Cursor to beginning of line
        left,
        /// Cursor to end of line
        right,
        /// Entire line
        both,
    };

    /// Erase Display (ED)
    /// `ESC [ <n> J`
    /// `n` is one of the `Display` variants
    pub fn display(d: Display) CSI {
        const params = switch (d) {
            .above => CSI.Params.one(1),
            .below => CSI.Params.none,
            .both => CSI.Params.one(2),
            .all => CSI.Params.one(3),
        };
        return CSI{
            .command = "J",
            .params = params,
        };
    }

    /// Erase Line (EL)
    /// `ESC [ <n> K`
    /// `n` is one of the `Line` variants
    pub fn line(l: Line) CSI {
        const params = switch (l) {
            .left => CSI.Params.one(1),
            .right => CSI.Params.none,
            .both => CSI.Params.one(2),
        };
        return CSI{
            .command = "K",
            .params = params,
        };
    }

    /// Erase Characters (ECH)
    /// `ESC [ <n> X`
    pub fn chars(n: u16) CSI {
        return CSI.n("X", n);
    }
};
