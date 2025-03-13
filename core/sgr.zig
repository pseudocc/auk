const std = @import("std");
const CSI = @import("control.zig").CSI;

const SGR = @This();

bold: ?bool = null,
faint: ?bool = null,
italic: ?bool = null,
underline: ?bool = null,
blink: ?bool = null,
inverse: ?bool = null,
conceal: ?bool = null,
strike: ?bool = null,

foreground: ?Color = null,
background: ?Color = null,

fn Buffer(comptime N: u8) type {
    return struct {
        data: [N]u16,
        i: u8 = 0,

        fn append(self: *Buffer, value: u16) void {
            std.debug.assert(self.i < N);
            self.data[self.i] = value;
            self.i += 1;
        }

        fn appendColor(self: *Buffer, offset: u16, color: Color) void {
            switch (color) {
                .c8 => |case| {
                    self.append(offset + @intFromEnum(case));
                },
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
                .reset => {
                    self.append(offset + 9);
                },
            }
        }

        fn slice(self: *const Buffer) []const u16 {
            if (@inComptime()) {
                const final = self.data[0..self.i].*;
                return &final;
            }
            return self.data[0..self.i];
        }
    };
}

pub fn csi(self: SGR) CSI {
    const buffer = Buffer(24){};

    if (self.bold) |enable| {
        buffer.append(if (enable) 1 else 22);
    }
    if (self.faint) |enable| {
        buffer.append(if (enable) 2 else 22);
    }
    if (self.italic) |enable| {
        buffer.append(if (enable) 3 else 23);
    }
    if (self.underline) |enable| {
        buffer.append(if (enable) 4 else 24);
    }
    if (self.blink) |enable| {
        buffer.append(if (enable) 5 else 25);
    }
    if (self.inverse) |enable| {
        buffer.append(if (enable) 7 else 27);
    }
    if (self.conceal) |enable| {
        buffer.append(if (enable) 8 else 28);
    }
    if (self.strike) |enable| {
        buffer.append(if (enable) 9 else 29);
    }

    if (self.foreground) |color| {
        buffer.appendColor(30, color);
    }
    if (self.background) |color| {
        buffer.appendColor(40, color);
    }

    return CSI{
        .command = "m",
        .params = .{ .disowned = buffer.slice() },
    };
}

pub fn format(
    self: SGR,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    try CSI.format(self.csi(), fmt, options, writer);
}

pub const Color = union(enum) {
    const Color16 = enum(u8) {
        black = 0,
        red = 1,
        green = 2,
        yellow = 3,
        blue = 4,
        magenta = 5,
        cyan = 6,
        white = 7,

        bright_black = 60,
        bright_red = 61,
        bright_green = 62,
        bright_yellow = 63,
        bright_blue = 64,
        bright_magenta = 65,
        bright_cyan = 66,
        bright_white = 67,
    };

    c8: Color16,
    c256: u8,
    rgb: [3]u8,
    reset,
};

pub const reset = csi(SGR{});
