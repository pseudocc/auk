const std = @import("std");
const auk = @import("auk");
const Terminal = @import("auk.terminal");

const stdout = std.io.getStdOut().writer();

var terminal: Terminal = undefined;

fn print(comptime fmt: []const u8, args: anytype) !void {
    const writer = terminal.tty.writer();
    try writer.print(fmt, args);
}

pub fn main() !void {
    try stdout.print("{s}\nPress 'q' to quit.\n", .{auk.description});

    terminal = try Terminal.init(.{});
    try terminal.into(.raw);
    defer {
        terminal.into(.canonical) catch {};
        print("Quitting...\n", .{}) catch {};
        std.Thread.sleep(std.time.ns_per_s / 2);
    }

    var reader = terminal.reader();
    try print("{}", .{auk.mouse.track});
    while (true) {
        const ev = reader.read() orelse continue;
        try print("{}{}", .{ auk.cursor.col(1), auk.erase.line(.right) });
        switch (ev) {
            .key => |code| {
                const Pack = packed struct(u16) {
                    base: u8,
                    shift: bool,
                    alt: bool,
                    ctrl: bool,
                    nonascii: bool,
                    padding: u4,
                };

                const pack: Pack = @bitCast(code);

                try print("key: ", .{});
                if (pack.ctrl) try print("ctrl+", .{});
                if (pack.alt) try print("alt+", .{});
                if (pack.shift) try print("shift+", .{});
                if (pack.nonascii) {
                    try print("nonascii {}", .{pack.base});
                } else if (std.ascii.isPrint(pack.base)) {
                    try print("{c}", .{pack.base});
                } else {
                    try print("{}", .{pack.base});
                }
                if (code == 'q') break;
            },
            .unicode => |code| {
                var buf: [4]u8 = undefined;
                _ = std.unicode.utf8Encode(code, &buf) catch unreachable;
                try print("unicode: {s}", .{buf});
            },
            .mouse => |mouse| try print("mouse: {}", .{mouse}),
            .unhandled => |queue| try print("unhandled: {any}", .{queue}),
        }
    }
}

test {
    std.testing.refAllDecls(auk);
    std.testing.refAllDecls(Terminal);
}
