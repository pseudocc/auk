const std = @import("std");
const auk = @import("auk");
const Terminal = @import("auk.terminal");

const stdout = std.io.getStdOut().writer();

var terminal: Terminal = undefined;

pub fn main() !void {
    try stdout.print("{s}\nPress 'q' to quit.\n", .{auk.description});

    terminal = try Terminal.init(.{});
    try terminal.into(.raw);
    var reader = terminal.reader();
    var writer = terminal.tty.writer();
    defer {
        terminal.into(.canonical) catch {};
        writer.print("\nQuitting...\n", .{}) catch {};
        terminal.deinit();
    }

    try writer.print("{}", .{auk.mouse.track});
    defer writer.print("{}", .{auk.mouse.untrack}) catch {};

    while (true) {
        const ev = reader.read() orelse continue;
        try writer.print("{}{}", .{ auk.cursor.col(1), auk.erase.line(.right) });
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

                try writer.print("key: ", .{});
                if (pack.ctrl) try writer.print("ctrl+", .{});
                if (pack.alt) try writer.print("alt+", .{});
                if (pack.shift) try writer.print("shift+", .{});
                if (pack.nonascii) {
                    try writer.print("nonascii {}", .{pack.base});
                } else if (std.ascii.isPrint(pack.base)) {
                    try writer.print("{c}", .{pack.base});
                } else {
                    try writer.print("{}", .{pack.base});
                }
                if (code == 'q') break;
            },
            .unicode => |code| {
                var buf: [4]u8 = undefined;
                _ = std.unicode.utf8Encode(code, &buf) catch unreachable;
                try writer.print("unicode: {s}", .{buf});
            },
            .mouse => |mouse| try writer.print("mouse: {}", .{mouse}),
            .unhandled => |queue| try writer.print("unhandled: {any}", .{queue}),
        }
    }
}

test {
    std.testing.refAllDecls(auk);
    std.testing.refAllDecls(Terminal);
}
