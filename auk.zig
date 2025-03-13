const std = @import("std");
const auk = @import("auk");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    try stdout.print("{s}\n", .{auk.description});
}
