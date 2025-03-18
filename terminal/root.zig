const Terminal = @This();

const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;

const File = std.fs.File;
const BufferedWriter = std.io.BufferedWriter(4096, File.Writer);

pub const Size = struct {
    width: u16,
    height: u16,
};

const Mode = enum {
    canonical,
    raw,
};

/// Raw input mode
/// default: Fully non-blocking
const RawInput = struct {
    vtime: u8 = 0,
    vmin: u8 = 0,
};

tty: File,
mode: Mode,
canonical: posix.termios,
raw: posix.termios,
buffered: BufferedWriter,

pub fn init(input: RawInput) !Terminal {
    const tty = try std.fs.cwd().openFileZ("/dev/tty", .{
        .mode = .read_write,
        .allow_ctty = true,
    });

    const canonical = try posix.tcgetattr(tty.handle);
    var raw = canonical;

    raw.iflag.BRKINT = false;
    raw.iflag.ICRNL = false;
    raw.iflag.INPCK = false;
    raw.iflag.ISTRIP = false;
    raw.iflag.IXON = false;
    raw.oflag.OPOST = false;
    raw.cflag.CSIZE = posix.CSIZE.CS8;
    raw.cflag.PARENB = false;
    raw.cflag.CSTOPB = false;
    raw.lflag.ECHO = false;
    raw.lflag.ICANON = false;
    raw.lflag.ISIG = false;
    raw.lflag.IEXTEN = false;

    raw.cc[@as(u32, @intFromEnum(posix.V.MIN))] = input.vmin;
    raw.cc[@as(u32, @intFromEnum(posix.V.TIME))] = input.vtime;

    return .{
        .tty = tty,
        .mode = .canonical,
        .canonical = canonical,
        .raw = raw,
        .buffered = .{ .unbuffered_writer = tty.writer() },
    };
}

pub fn into(self: *Terminal, mode: Mode) !void {
    if (mode == self.mode) return;

    const termios = switch (mode) {
        .canonical => self.canonical,
        .raw => self.raw,
    };

    self.mode = mode;
    try posix.tcsetattr(self.tty.handle, .FLUSH, termios);
}

pub fn deinit(self: *Terminal) void {
    self.into(.canonical) catch {};
    self.tty.close();
}

pub fn size(self: *Terminal) !Size {
    var ws: linux.winsize = undefined;
    const ret = linux.ioctl(self.tty.handle, linux.T.IOCGWINSZ, @intFromPtr(&ws));
    switch (linux.E.init(ret)) {
        .SUCCESS => {},
        else => return error.IOCGWINSZ,
    }
    return .{ .width = ws.col, .height = ws.row };
}

pub fn reader(self: Terminal) event.Reader {
    return std.mem.zeroInit(event.Reader, .{ .tty = self.tty });
}

const event = @import("event.zig");
pub const keys = event.keys;
pub const mouses = event.mouses;
