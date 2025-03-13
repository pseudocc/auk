const std = @import("std");
const CSI = @import("control.zig").CSI;

/// SGR Intermediate Representation
/// `ESC [ <params> m`
/// This follows the `Builder` design pattern.
pub const IR = struct {
    params: std.ArrayList(u16),

    pub fn csi(self: IR) CSI {
        return CSI{
            .command = "m",
            .params = .{ .disowned = self.params.items },
        };
    }

    pub fn bold(self: *IR, value: bool) !*IR {
        try self.params.append(if (value) 1 else 22);
        return self;
    }

    pub fn faint(self: *IR, value: bool) !*IR {
        try self.params.append(if (value) 2 else 22);
        return self;
    }

    pub fn italic(self: *IR, value: bool) !*IR {
        try self.params.append(if (value) 3 else 23);
        return self;
    }

    pub fn underline(self: *IR, value: bool) !*IR {
        try self.params.append(if (value) 4 else 24);
        return self;
    }

    pub fn blink(self: *IR, value: bool) !*IR {
        try self.params.append(if (value) 5 else 25);
        return self;
    }

    pub fn inverse(self: *IR, value: bool) !*IR {
        try self.params.append(if (value) 7 else 27);
        return self;
    }

    pub fn conceal(self: *IR, value: bool) !*IR {
        try self.params.append(if (value) 8 else 28);
        return self;
    }

    pub fn strike(self: *IR, value: bool) !*IR {
        try self.params.append(if (value) 9 else 29);
        return self;
    }

    pub fn foreground(self: *IR, value: Color) !*IR {
        return self.setColor(value, 30);
    }

    pub fn background(self: *IR, value: Color) !*IR {
        return self.setColor(value, 40);
    }

    fn setColor(self: *IR, value: Color, offset: u16) !*IR {
        switch (value) {
            .c8 => |case| {
                try self.params.append(offset + @intFromEnum(case));
            },
            .c256 => |case| {
                const params = try self.params.addManyAsArray(3);
                params.* = .{ offset + 8, 5, case };
            },
            .rgb => |case| {
                const params = try self.params.addManyAsArray(5);
                params.* = .{ offset + 8, 2, case[0], case[1], case[2] };
            },
            .reset => {
                try self.params.append(offset + 9);
            },
        }
        return self;
    }

    pub fn format(
        self: IR,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try self.csi().format(fmt, options, writer);
    }
};

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

const Options = struct {
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
};

fn construct(ir: *IR, options: Options) !void {
    inline for (.{
        "bold",
        "faint",
        "italic",
        "underline",
        "blink",
        "inverse",
        "conceal",
        "strike",
        "foreground",
        "background",
    }) |key| {
        if (@field(options, key)) |value| {
            try @field(IR, key)(ir, value);
        }
    }
}

/// SGR CSI constructor
/// `ESC [ <params> m`
pub fn from(buffer: []u8, options: Options) !CSI {
    var fba = std.heap.FixedBufferAllocator.init(buffer);
    var ir = IR{ .params = std.ArrayList(u16).init(fba.allocator()) };
    try construct(&ir, options);
    return ir.csi();
}

/// SGR CSI constructor
/// `ESC [ <params> m`
/// Caller owns the memory of the returned `CSI.params.owned`.
pub fn alloc(allocator: std.mem.Allocator, options: Options) !CSI {
    var ir = IR{ .params = std.ArrayList(u16).init(allocator) };
    try construct(&ir, options);
    const params = try ir.params.toOwnedSlice();
    return CSI{
        .command = "m",
        .params = .{ .owned = params },
    };
}
