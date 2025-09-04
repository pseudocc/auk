# auk

A Zig library for POSIX terminals, providing terminal control
capabilities through escape sequences and input event handling.
Build TUI libraries and applications on top of it.

## Zig modules

### auk
Send various terminal escape sequences for:
- **Cursor positioning and movement**
- **Screen clearing and line erasing**
- **Mouse tracking control**
- **Terminal formatting and styling**

**Usage:**
```zig
const auk = @import("auk");
const writer: std.io.Writer = ...;

// Create colorful text using SGR (Select Graphic Rendition)
try writer.print("{f}Red text{f}", .{ auk.SGR{ .fg = .red }, auk.SGR{} });
try writer.print("{f}Bold blue text{f}", .{ auk.SGR{ .fg = .blue, .bold = true }, auk.SGR{} });

// Clear screen
try writer.print("{f}", .{auk.erase.display(.all)});

// Move cursor
try writer.print("{f}", .{auk.cursor.goto(10, 5)}); // Move to column 10, row 5
try writer.print("{f}", .{auk.cursor.up(3)});       // Move up 3 lines
try writer.print("{f}", .{auk.cursor.col(1)});      // Move to column 1
```

### auk.terminal
Core building blocks for creating terminal applications:
- **Terminal Mode Control**: Switch between canonical and raw terminal
modes
- **Event Reader**: Comprehensive input event handling system
- **Input Processing**: Handle keyboard, mouse, and Unicode events

**Usage:**
Take a look at [auk.zig](auk.zig) for a complete example of how to use
the terminal event loop system.

## Getting Started

### Use auk in your Zig project

Download package cache and update rev in your `build.zig.zon`.
```bash
zig fetch --save git+https://github.com/pseudocc/auk.git
```

Add the modules you need in your `build.zig`, something like:
```zig
const auk_dep = b.dependency("auk", .{});
const auk_core_module = auk_dep.module("auk");
const auk_terminal_module = auk_dep.module("auk.terminal");
```

### Running the Demo

```bash
# Using Zig
zig build run

# Using Nix
nix run github:pseudocc/auk
```

The demo application will:
- Display the library description
- Enter raw terminal mode
- Enable mouse tracking
- Display real-time input events (keyboard, mouse, Unicode)
- Exit when 'q' is pressed

## Event Types

The `auk.terminal` event reader supports several event types:

- **Key Events**: Regular keyboard input with modifier key support
(Ctrl, Alt, Shift)
- **Mouse Events**: Mouse movement, clicks, and scroll events
- **Unicode Events**: Full Unicode character input
- **Unhandled Events**: Raw input sequences that don't match known
patterns

## Development

This project includes a Nix flake for easy development environment
setup:

```bash
# Enter development shell
nix develop

# Build and test (just like other Zig projects)
zig build
zig test
```

## License

This project is licensed under a custom license. See the
[LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull
requests.
