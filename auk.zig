const std = @import("std");
const auk = @import("auk");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    try auk.hello(stdout);
}
