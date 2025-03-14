const std = @import("std");

const esc = std.ascii.control_code.esc;

fn printEsc(comptime fmt: []const u8, context: anytype, writer: anytype) !void {
    switch (fmt.len) {
        0 => return writer.writeByte(esc),
        1 => if (fmt[0] == 's') {
            return writer.print("\\x{x}", .{esc});
        },
        else => {},
    }
    std.fmt.invalidFmtError(fmt, context);
}

/// Escape Sequence
pub const ESC = struct {
    command: []const u8,
    n: ?u8 = null,

    pub fn format(
        self: ESC,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try printEsc(fmt, self, writer);
        if (self.n) |n| {
            try writer.print("{d}", .{n});
        }
        try writer.print("{s}", .{self.command});
    }
};

/// Control Sequence Introducer (CSI) Sequence
/// `ESC [ <params> <command>]`
pub const CSI = struct {
    pub const Params = union(enum) {
        const Sentinel = std.math.maxInt(u16);

        none: void,
        owned: [2]u16,
        disowned: []const u16,

        pub fn one(param: u16) Params {
            std.debug.assert(param != Sentinel);
            return .{ .owned = .{ param, Sentinel } };
        }

        pub fn two(param0: u16, param1: u16) Params {
            std.debug.assert(param0 != Sentinel);
            std.debug.assert(param1 != Sentinel);
            return .{ .owned = .{ param0, param1 } };
        }
    };

    /// DEC Private Mode
    /// `ESC [ ? <params> <command>]`
    dec: bool = false,
    maybe_empty: bool = false,
    command: []const u8,
    params: Params = .none,

    pub const Switch = struct {
        on: CSI,
        off: CSI,

        pub fn init(comptime code: u16, dec: bool) Switch {
            return .{
                .on = .{
                    .dec = dec,
                    .command = "h",
                    .params = Params.one(code),
                },
                .off = .{
                    .dec = dec,
                    .command = "l",
                    .params = Params.one(code),
                },
            };
        }
    };

    /// Internal Helper Function
    /// one parameter without maybe_empty flag
    pub fn v(comptime command: []const u8, param: u16) CSI {
        return CSI{
            .command = command,
            .params = CSI.Params.one(param),
        };
    }

    /// Internal Helper Function
    /// one parameter with maybe_empty flag
    pub fn n(comptime command: []const u8, param: u16) CSI {
        return CSI{
            .command = command,
            .params = CSI.Params.one(param),
            .maybe_empty = true,
        };
    }

    pub fn format(
        self: CSI,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const params: []const u16 = switch (self.params) {
            .owned => |case| std.mem.sliceTo(&case, CSI.Params.Sentinel),
            .disowned => |case| case,
            .none => &.{},
        };

        if (self.maybe_empty) {
            var skip = true;
            for (params) |param| {
                if (param != 0) {
                    skip = false;
                    break;
                }
            }
            if (skip) {
                return;
            }
        }

        try printEsc(fmt, self, writer);
        try writer.writeByte('[');
        if (self.dec) {
            try writer.writeByte('?');
        }

        for (params, 0..) |param, i| {
            if (i != 0) {
                try writer.writeByte(';');
            }
            try writer.print("{d}", .{param});
        }
        try writer.print("{s}", .{self.command});
    }
};

pub fn Expect(comptime T: type) type {
    return struct {
        expected: []const u8,
        actual: T,

        pub fn check(self: @This()) !void {
            try std.testing.expectFmt(self.expected, "{}", .{self.actual});
        }
    };
}

test ESC {
    const E = Expect(ESC);
    const cases = .{
        .{ "\x1bA", ESC{ .command = "A" } },
        .{ "\x1b1A", ESC{ .command = "A", .n = 1 } },
        .{ "\x1b11B", ESC{ .command = "B", .n = 11 } },
    };
    inline for (cases) |c| {
        const e = E{ .expected = c[0], .actual = c[1] };
        try e.check();
    }
}

test CSI {
    const E = Expect(CSI);
    const cases = .{
        .{
            "\x1b[A",
            CSI{ .command = "A" },
        },
        .{
            "\x1b[1A",
            CSI{ .command = "A", .params = CSI.Params.one(1) },
        },
        .{ "\x1b[1A", CSI.v("A", 1) },
        .{ "", CSI.n("A", 0) },
        .{
            "\x1b[?1A",
            CSI{ .command = "A", .params = CSI.Params.one(1), .dec = true },
        },
        .{
            "\x1b[1;2A",
            CSI{ .command = "A", .params = CSI.Params.two(1, 2) },
        },
        .{
            "\x1b[1;2;3;4B",
            CSI{ .command = "B", .params = .{ .disowned = &.{ 1, 2, 3, 4 } } },
        },
    };

    inline for (cases) |c| {
        const e = E{ .expected = c[0], .actual = c[1] };
        try e.check();
    }
}
