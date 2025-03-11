pub fn hello(writer: anytype) !void {
    try writer.print("🌊🐦\n", .{});
}
