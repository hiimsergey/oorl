const std = @import("std");

var stdout_buf: [512]u8 = undefined;
var stderr_buf: [512]u8 = undefined;

pub var stdout = std.fs.File.stdout().writer(&stdout_buf);
pub var stderr = std.fs.File.stderr().writer(&stderr_buf);

pub fn println(comptime fmt: []const u8, args: anytype) void {
	stdout.interface.print(fmt ++ "\n", args) catch {};
}
pub fn errln(comptime fmt: []const u8, args: anytype) void {
	_ = stderr.interface.write("\x1b[31merror: ") catch {};
	stderr.interface.print(fmt ++ "\n", args) catch {};
}
pub fn err(comptime fmt: []const u8, args: anytype) void {
	_ = stderr.interface.write("\x1b[31merror: ") catch {};
	stderr.interface.print(fmt, args) catch {};
}

pub fn flush_stdout() void {
	stdout.interface.flush() catch {};
}
pub fn flush_stderr() void {
	stderr.interface.flush() catch {};
}
