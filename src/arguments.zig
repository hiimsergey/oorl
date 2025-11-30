const std = @import("std");
const log = @import("log.zig");

const StatFileError = std.fs.Dir.StatFileError;

const Generic = error.Generic;

const Expecting = enum(u8) {none, number, string, input};

const HELP = "oorl - TODO description";
const ERROR_STRING_NUMBER = "-d/-f/-l: ";

pub fn eql_either(a: []const u8, b1: []const u8, b2: []const u8) bool {
	return std.mem.eql(u8, a, b1) or std.mem.eql(u8, a, b2);
}

pub fn validate(args: [][:0]u8) !void {
	if (args.len == 0) {
		log.println(HELP, .{});
		return Generic;
	}

	var expecting = Expecting.none;

	for (args) |arg| switch (expecting) {
		.number => {
			_ = std.fmt.parseInt(u32, arg, 10) catch |err| {
				log.err(ERROR_STRING_NUMBER, .{});
				
				switch (err) {
					error.Overflow => log.stderr.interface.print(
						"The number '{s}' is too big to parse!\n", .{arg}) catch {},
					error.InvalidCharacter => log.stderr.interface.print(
						"'{s}' is not a number!\n", .{arg}) catch {}
				}
				return Generic;
			};
			expecting = .input;
		},
		.string => expecting = .none,
		.input, .none => {
			if (eql_either(arg, "--help", "-h")) {
				log.println(HELP, .{});
				return Generic;
			}
			if (eql_either(arg, "--string", "-s")) {
				expecting = .string;
				continue;
			}
			if (eql_either(arg, "--first", "-f") or
				eql_either(arg, "--last", "-l") or
				eql_either(arg, "--delay", "-d")) {
				expecting = .number;
				continue;
			}
			if (arg[0] == '-') {
				log.errln("Invalid flag: {s}", .{arg});
				return Generic;
			}
			try validate_file(arg);
		}
	};

	switch (expecting) {
		.number => {
			log.err(ERROR_STRING_NUMBER, .{});
			log.stderr.interface.print("Expected number but none given!\n", .{})
			catch {};
			return Generic;
		},
		.string => {
			log.errln("-s: Expected string but none given!", .{});
			return Generic;
		},
		.input => {
			log.errln("The last flags implied an input following but none came!", .{});
			return Generic;
		},
		.none => {}
	}
}

fn validate_file(path: []const u8) !void {
	_ = std.fs.cwd().statFile(path) catch |err| {
		log.err("'{s}': ", .{path});
		const errmsg = switch (err) {
			StatFileError.AccessDenied => "Access denied!",
			StatFileError.FileNotFound => "No such file!",
			StatFileError.IsDir => "Is a directory!",
			StatFileError.PermissionDenied => "Permission denied!",
			StatFileError.SystemResources => "System error in opening!",
			else => "Unexpected error when opening!"
		};
		log.stderr.interface.print("{s}\n", .{errmsg}) catch {};
		return Generic;
	};
}
