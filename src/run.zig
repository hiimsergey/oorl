const builtin = @import("builtin");
const std = @import("std");
const arguments = @import("arguments.zig");

const eql_either = arguments.eql_either;

const Expecting = enum(u8) {first, last, delay, string, input, none};

const Options = struct {
	first: ?u32 = null,
	last: ?u32 = null,
	delay: ?u32 = null,
};

const START = switch (builtin.os.tag) {
	.linux, .freebsd, .openbsd => "xdg-open",
	.macos, .haiku => "open",
	.windows => "start",
	else => @compileError("Unsupported operating system!")
};

pub fn run(args: [][:0]u8) !void {
	var expecting = Expecting.none;
	var options = Options{};

	for (args) |arg| switch (expecting) {
		.first => options.first = try std.fmt.parseInt(u32, arg, 10),
		.last => options.last = try std.fmt.parseInt(u32, arg, 10),
		.delay => options.delay = try std.fmt.parseInt(u32, arg, 10),
		.string => {
			try run_string(arg, &options);
			expecting = .none;
		},
		.input => if (eql_either(arg, "--string", "-s")) { expecting = .string; }
			else try run_file(arg, &options),
		.none => if (eql_either(arg, "--first", "-f")) { expecting = .first; }
			else if (eql_either(arg, "--last", "-l")) { expecting = .last; }
			else if (eql_either(arg, "--delay", "-d")) { expecting = .delay; }
			else if (eql_either(arg, "--string", "-s")) { expecting = .string; }
			else try run_file(arg, &options)
	};
}

fn run_string(string: []const u8, options: *Options) !void {
	std.debug.print(
		\\running the string '{s}'
		\\first: {d}
		\\last: {d}
		\\delay: {d}
		\\---
		\\
		, .{string, options.first orelse 255, options.last orelse 255, options.delay orelse 255}
	);
	options.* = .{};
}

fn run_file(file: []const u8, options: *Options) !void {
	std.debug.print(
		\\running the file '{s}'
		\\first: {d}
		\\last: {d}
		\\delay: {d}
		\\---
		\\
		, .{file, options.first orelse 255, options.last orelse 255, options.delay orelse 255}
	);
	options.* = .{};
}
