const std = @import("std");

const File = std.fs.File;
const cc = std.ascii.control_code;

/// This helper struct remap complex keys to simple u16
/// values which provides a friendly interface
/// ```zig
/// switch (event.key) {
///    keys.left => move_left(...),
///    keys.f(1) => show_help(...),
///    keys.ctrl | keys.c => exit(...),
///    ...
/// }
/// ```
pub const keys = struct {
    pub const Pack = packed struct(u16) {
        base: u8,
        shift: bool,
        alt: bool,
        crtl: bool,
        noniscii: bool,
        padding: u4,
    };

    pub const left = 0x80;
    pub const right = 1 + left;
    pub const up = 2 + left;
    pub const down = 3 + left;
    pub const home = 4 + left;
    pub const end = 5 + left;
    pub const page_up = 6 + left;
    pub const page_down = 7 + left;
    pub const insert = 8 + left;
    pub const delete = 9 + left;
    pub const space = 10 + left;
    pub const backspace = 11 + left;
    pub const enter = 12 + left;
    pub const escape = 13 + left;
    pub const tab = 14 + left;
    pub const menu = 15 + left;

    pub const shift = 0x100;
    pub const alt = 0x200;
    pub const ctrl = 0x400;
    pub const noniscii = 0x800;

    /// Function keys
    pub fn f(n: u16) u16 {
        return menu + n;
    }

    fn one(code: u8) u16 {
        return switch (code) {
            cc.bs => backspace | ctrl,
            cc.del => backspace,
            cc.cr => enter,
            cc.ht => tab,
            else => code | @as(u16, if (std.ascii.isAscii(code)) 0 else noniscii),
        };
    }
};

/// This helper struct follows the mouse tracking report's
/// format and provides identical interface to keys
/// ```zig
/// switch (event.mouse) {
///   mouses.left => left_click(...),
///   mouses.wheel_up => scroll_up(...),
///   mouses.extra(1) | keys.ctrl => do_something(...),
///   ...
/// }
/// ```
pub const mouses = struct {
    pub const left = 0;
    pub const middle = 1;
    pub const right = 2;
    pub const release = 3;

    pub const wheel_up = 0x40;
    pub const wheel_down = 0x41;
    pub const wheel_left = 0x42;
    pub const wheel_right = 0x43;

    pub const shift = 0x4;
    pub const alt = 0x8;
    pub const ctrl = 0x10;
    pub const motion = 0x20;

    pub fn extra(n: u8) u8 {
        return 128 + n;
    }
};

const Event = union(enum) {
    const Mouse = struct {
        button: u8,
        x: u8,
        y: u8,
    };

    const Unhandled = union(enum) {
        csi_tl: u8,
        unknown: []const u8,
    };

    key: u16,
    unicode: u21,
    mouse: Mouse,
    unhandled: Unhandled,
};

fn parseCsi(data: []const u8) ?Event {
    var mod: u16 = 0;
    const params_end = if (std.mem.indexOfScalar(u8, data, ';')) |i| semi: {
        const mod_param = data[i + 1] - '1';
        if (mod_param & 1 != 0) mod |= keys.shift;
        if (mod_param & 2 != 0) mod |= keys.alt;
        if (mod_param & 4 != 0) mod |= keys.ctrl;
        break :semi i;
    } else data.len - 1;

    const command = data[data.len - 1];
    const param = std.fmt.parseInt(u8, data[0..params_end], 10);

    const key = switch (command) {
        'A' => keys.up,
        'B' => keys.down,
        'C' => keys.right,
        'D' => keys.left,
        'H' => keys.home,
        'F' => keys.end,
        'P' => keys.f(1),
        'Q' => keys.f(2),
        'S' => keys.f(4),
        'Z' => keys.shift | keys.tab, // backtab
        'u' => keys.one(param catch return null),
        '~' => switch (param catch return null) {
            2 => keys.insert,
            3 => keys.delete,
            5 => keys.page_up,
            6 => keys.page_down,
            13 => keys.f(3),
            15 => keys.f(5),
            17 => keys.f(6),
            18 => keys.f(7),
            19 => keys.f(8),
            20 => keys.f(9),
            21 => keys.f(10),
            23 => keys.f(11),
            24 => keys.f(12),
            29 => keys.menu,
            else => |p| return .{ .unhandled = .{ .csi_tl = p } },
        },
        else => return null,
    };

    return .{ .key = key | mod };
}

const BUFSZ = 4096;
const QMARK = std.unicode.utf8Decode("�") catch unreachable;

pub const Reader = struct {
    tty: File,
    timeout: i32 = 10,
    // Super efficient 2 pointers buffer
    buffer: [BUFSZ]u8,
    start: usize,
    end: usize,

    fn process(self: *Reader) ?Event {
        const queue = self.buffer[self.start..self.end];
        if (queue.len == 0) return null;
        var processed: usize = 0;

        defer {
            self.start += processed;
            if (self.start > BUFSZ / 2) {
                const length = self.end - self.start;
                @memcpy(self.buffer[0..length], self.buffer[self.start..]);
                self.start = 0;
                self.end = length;
            }
        }

        // unicode
        {
            const n = std.unicode.utf8ByteSequenceLength(queue[0]) catch 1;
            if (n != 1) {
                const code = std.unicode.utf8Decode(queue[0..n]) catch QMARK;
                processed = n;
                return .{ .unicode = code };
            }
        }

        var may_process: usize = 1;
        if (queue[0] == cc.esc and queue.len > 1) {
            const search_start: u16 = if (queue[1] == cc.esc) 2 else 1;
            may_process = std.mem.indexOfPos(u8, queue, search_start, &.{cc.esc}) orelse queue.len;

            if (may_process == 6 and std.mem.startsWith(u8, queue, "\x1b[M")) {
                processed = 6;
                return .{
                    .mouse = .{
                        .button = queue[3] - 32,
                        .x = queue[4] - 32,
                        .y = queue[5] - 32,
                    },
                };
            }
        }

        const maybe_key: ?Event = switch (may_process) {
            0 => unreachable,
            1 => key: {
                processed = 1;
                break :key .{ .key = keys.one(queue[0]) };
            },
            else => key: {
                processed = may_process;
                if (may_process == 2)
                    break :key .{ .key = keys.one(queue[1]) | keys.alt };
                switch (queue[1]) {
                    'O' => {
                        processed = 3;
                        break :key .{ .key = keys.f(queue[2] - 'O') };
                    },
                    '[' => {
                        processed = final: {
                            for (2..may_process) |i| {
                                switch (queue[i]) {
                                    0x40...0x7e => break :final i + 1,
                                    else => {},
                                }
                            }
                            break :key null;
                        };
                        break :key parseCsi(queue[2..processed]);
                    },
                    else => break :key null,
                }
            },
        };

        return maybe_key orelse .{
            .unhandled = .{ .unknown = queue[0..may_process] },
        };
    }

    pub fn read(self: *Reader) ?Event {
        if (self.process()) |event| return event;

        var pollfd = std.posix.pollfd{
            .fd = self.tty.handle,
            .events = std.posix.POLL.IN,
            .revents = 0,
        };
        const n = std.posix.poll(@ptrCast(&pollfd), self.timeout)
            catch return null;
        if (n == 0) return null;

        const bytes_read = self.tty.read(self.buffer[self.end..])
            catch return null;
        if (bytes_read == 0) return null;

        self.end += bytes_read;
        return self.process();
    }
};
