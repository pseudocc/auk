const std = @import("std");
const CSI = @import("control.zig").CSI;

const SGR = @This();

/// Bold (1) Unbold (22)
bd: ?bool = null,
/// Faint (2) Unfaint (22)
ft: ?bool = null,
/// Italic (3) Unitalic (23)
it: ?bool = null,
/// Underline (4) Ununderline (24)
ul: ?bool = null,
/// Blink (5) Unblink (25)
bl: ?bool = null,
/// Inverse (7) Uninverse (27)
rv: ?bool = null,
/// Conceal (8) Reveal (28)
hd: ?bool = null,
/// Strike (9) Unstrike (29)
st: ?bool = null,

/// Foreground color
fg: ?Color = null,
/// Background color
bg: ?Color = null,

fn Buffer(comptime N: u8) type {
    return struct {
        const Self = @This();

        data: [N]u16 = std.mem.zeroes([N]u16),
        i: u8 = 0,

        fn init(sgr: SGR) Self {
            var buffer = Self{};
            if (sgr.bd) |enable| buffer.append(if (enable) 1 else 22);
            if (sgr.ft) |enable| buffer.append(if (enable) 2 else 22);
            if (sgr.it) |enable| buffer.append(if (enable) 3 else 23);
            if (sgr.ul) |enable| buffer.append(if (enable) 4 else 24);
            if (sgr.bl) |enable| buffer.append(if (enable) 5 else 25);
            if (sgr.rv) |enable| buffer.append(if (enable) 7 else 27);
            if (sgr.hd) |enable| buffer.append(if (enable) 8 else 28);
            if (sgr.st) |enable| buffer.append(if (enable) 9 else 29);
            if (sgr.fg) |color| buffer.appendColor(30, color);
            if (sgr.bg) |color| buffer.appendColor(40, color);
            return buffer;
        }

        fn append(self: *Self, value: u16) void {
            std.debug.assert(self.i < N);
            self.data[self.i] = value;
            self.i += 1;
        }

        fn appendColor(self: *Self, offset: u16, color: Color) void {
            switch (color) {
                .black => self.append(offset + 0),
                .red => self.append(offset + 1),
                .green => self.append(offset + 2),
                .yellow => self.append(offset + 3),
                .blue => self.append(offset + 4),
                .magenta => self.append(offset + 5),
                .cyan => self.append(offset + 6),
                .white => self.append(offset + 7),

                .b_black => self.append(offset + 60),
                .b_red => self.append(offset + 61),
                .b_green => self.append(offset + 62),
                .b_yellow => self.append(offset + 63),
                .b_blue => self.append(offset + 64),
                .b_magenta => self.append(offset + 65),
                .b_cyan => self.append(offset + 66),
                .b_white => self.append(offset + 67),

                .c256 => |case| {
                    const params = self.data[self.i..];
                    std.debug.assert(params.len >= 3);
                    params[0] = offset + 8;
                    params[1] = 5;
                    params[2] = case;
                    self.i += 3;
                },

                .rgb => |case| {
                    const params = self.data[self.i..];
                    std.debug.assert(params.len >= 5);
                    params[0] = offset + 8;
                    params[1] = 2;
                    params[2] = case[0];
                    params[3] = case[1];
                    params[4] = case[2];
                    self.i += 5;
                },

                .reset => self.append(offset + 9),
            }
        }

        fn csi(self: *const Self) CSI {
            return CSI{
                .command = "m",
                .params = .{ .disowned = self.data[0..self.i] },
            };
        }
    };
}

pub fn format(
    self: SGR,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    const buffer = Buffer(24).init(self);
    try CSI.format(buffer.csi(), fmt, options, writer);
}

pub const Color = union(enum) {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,

    b_black,
    b_red,
    b_green,
    b_yellow,
    b_blue,
    b_magenta,
    b_cyan,
    b_white,

    c256: u8,
    rgb: [3]u8,
    reset,
};

pub const reset = SGR{};

test SGR {
    const E = @import("control.zig").Expect(SGR);
    const cases = .{
        .{ "\x1b[m", SGR{} },
        .{ "\x1b[1m", SGR{ .bd = true } },
        .{ "\x1b[31m", SGR{ .fg = .red } },
        .{
            "\x1b[38;5;1m",
            SGR{ .fg = .{ .c256 = 1 } },
        },
        .{
            "\x1b[38;2;11;23;58m",
            SGR{ .fg = .{ .rgb = .{ 11, 23, 58 } } },
        },
        .{
            "\x1b[39m",
            SGR{ .fg = .reset },
        },
        .{
            "\x1b[1;31m",
            SGR{ .bd = true, .fg = .red },
        },
    };

    inline for (cases) |c| {
        const e = E{ .expected = c[0], .actual = c[1] };
        try e.check();
    }
}
