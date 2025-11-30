const builtin = @import("builtin");
const std = @import("std");
const arguments = @import("arguments.zig");
const ds = @import("ds.zig");
const log = @import("log.zig");

const eql_either = arguments.eql_either;

const Expecting = enum(u8) {first, last, delay, string, input, none};

const Tracker = struct {
	options: struct {
		first: ?u32 = null,
		last: ?u32 = null,
		delay: ?u32 = null,
	},
	firsts: ds.HeadBuffer,
	lasts: ds.RingBuffer,
	vtable: struct {
		firsts_add: *const TrackerFn,
		lasts_add: *const TrackerFn,
		all_add: *const Tracker,
		delay_do: *const Tracker,
		firsts_final: *const Tracker,
		lasts_final: *const Tracker
	},

	const TrackerFn = fn (*Tracker, []const u8) void;

	// TODO USE
	fn deinit(self: *Tracker, allocator: std.mem.Allocator) void {
		self.firsts.deinit(allocator);
		self.lasts.deinit(allocator);
	}

	// TODO ADD method to initialize containers and assign the functions below

	fn noop(_: *Tracker, _: []const u8) void {}
	fn firsts_add_fn(tracker: *Tracker, item: []const u8) void {
		tracker.firsts.add(item);
	}
	fn lasts_add_fn(tracker: *Tracker, item: []const u8) void {
		tracker.lasts.add(item);
	}
	fn all_add_fn(tracker: *Tracker, item: []const u8) void {
		spawn(item);
	}
	fn delay_do_fn(tracker: *Tracker, _: []const u8) void {
		std.Thread.sleep(tracker.delay * 1_000);
	}
	fn firsts_final_fn(tracker: *Tracker, _: []const u8) void {
		for (tracker.firsts.buf[0..tracker.firsts.head]) |item| spawn(item);
	}
	fn lasts_final_fn(tracker: *Tracker, _: []const u8) void {
		if (tracker.lasts.got_full)
			for (tracker.lasts.buf[tracker.lasts.head..]) |item| spawn(item);
		for (tracker.lasts.buf[0..tracker.lasts.head]) |item| spawn(item);
	}
};
const Iterator = struct {
	vtable: struct {
		next: *const fn (*anyopaque) ?[]const u8,
	},

	fn next(self: *Iterator) ?[]const u8 {
		return self.vtable.next(self);
	}

	fn run(self: *Iterator, allocator: std.mem.Allocator, tracker: *Tracker) !void {
		var firsts: ds.HeadBuffer, var lasts: ds.RingBuffer = .{undefined, undefined};
		const tracking_fn = tracking.get_fn(allocator, options, &firsts, &lasts);

		// TODO NOW PLAN
		// assign funcptrs here
		// change function signatures of funcptrs so that spawn() can be properly used
		// start spawning
	}
};

const StringProcessor = struct {
	interface: Iterator,
	string: []const u8,
	token_iterator: std.mem.TokenIterator(u8, .scalar),

	fn init(string: []const u8) StringProcessor {
		var result: StringProcessor = undefined;
		result.string = string;
		result.token_iterator = std.mem.tokenizeScalar(u8, string, ' ');
		result.interface.vtable.next = result.token_iterator.next;
	}
};
const FileProcessor = struct {
	interface: Iterator,
	buf: [1024] u8,
	reader: std.fs.File.Reader,

	fn init(file: std.fs.File) FileProcessor {
		var result: FileProcessor = undefined;
		result.reader = file.reader(&result.buf);
		result.interface.vtable.next = next;
	}

	fn next(reader: *std.fs.File.Reader) ?[]const u8 {
		return reader.interface.takeDelimiter('\n') catch null;
	}
};

const START = switch (builtin.os.tag) {
	.linux, .freebsd, .openbsd => "xdg-open",
	.macos, .haiku => "open",
	.windows => "start",
	else => @compileError("Unsupported operating system!")
};

pub fn run_args(allocator: std.mem.Allocator, args: [][:0]u8) !void {
	var expecting = Expecting.none;

	var tracker = Tracker{};
	defer tracker.deinit(allocator);

	for (args) |arg| switch (expecting) {
		.first => tracker.options.first = try std.fmt.parseInt(u32, arg, 10),
		.last => tracker.options.last = try std.fmt.parseInt(u32, arg, 10),
		.delay => tracker.options.delay = try std.fmt.parseInt(u32, arg, 10),
		.string => {
			try run_string(allocator, arg, &tracker);
			expecting = .none;
		},
		.input => if (eql_either(arg, "--string", "-s")) { expecting = .string; }
			else try run_file(allocator, arg, &tracker),
		.none => if (eql_either(arg, "--first", "-f")) { expecting = .first; }
			else if (eql_either(arg, "--last", "-l")) { expecting = .last; }
			else if (eql_either(arg, "--delay", "-d")) { expecting = .delay; }
			else if (eql_either(arg, "--string", "-s")) { expecting = .string; }
			else try run_file(allocator, arg, &tracker)
	};
}

fn run_string(allocator: std.mem.Allocator, string: []const u8, tracker: *Tracker) !void {
	const sp = StringProcessor.init(string);
	try sp.interface.run(allocator, tracker);
	tracker.options = .{};
}

fn run_file(allocator: std.mem.Allocator, path: []const u8, tracker: *Tracker) !void {
	var file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
	defer file.close();
	
	const fp = FileProcessor.init(file);
	try fp.interface.run(allocator, tracker);
	tracker.options = .{};
}

fn spawn(allocator: std.mem.Allocator, item: []const u8) void {
	var child = std.process.Child.init(&.{ START, item }, allocator);
	const term = child.spawnAndWait() catch {
		log.errln("'{s}': Failed to spawn process!");
		return;
	};
	if (term.Exited != 0) log.errln("'{s}': Spawning process didn't quite succeed!");
}
