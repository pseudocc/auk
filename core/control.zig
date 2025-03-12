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
        try writer.writeByte(self.command);
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

        pub fn one(v: u16) Params {
            return two(v, Sentinel);
        }

        pub fn two(v0: u16, v1: u16) Params {
            std.debug.assert(v0 != Sentinel);
            std.debug.assert(v1 != Sentinel);
            return .{ .owned = .{ v0, v1 } };
        }
    };

    /// DEC Private Mode
    /// `ESC [ ? <params> <command>]`
    dec: bool = false,
    command: []const u8,
    params: Params = .none,

    pub const Switch = struct {
        on: CSI,
        off: CSI,

        fn init(comptime code: u8, dec: bool) Switch {
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

    pub fn format(
        self: CSI,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try printEsc(fmt, self, writer);
        try writer.writeByte('[');
        if (self.dec) {
            try writer.writeByte('?');
        }

        const params: []const u8 = switch (self.params) {
            .owned => |case| std.mem.sliceTo(&case, CSI.Params.Sentinel),
            .disowned => |case| case,
            .none => &.{},
        };
        for (params, 0..) |param, i| {
            if (i != 0) {
                try writer.writeByte(';');
            }
            try writer.print("{d}", .{param});
        }
        try writer.print("{s}", .{self.command});
    }
};
