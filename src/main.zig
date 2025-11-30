const std = @import("std");
const arguments = @import("arguments.zig");
const log = @import("log.zig");
const run = @import("run.zig");

const AllocatorWrapper = @import("allocator.zig").AllocatorWrapper;

const Options = struct {
	string_mode: bool,
	sanitize: bool,
	number: union(enum) {
		none: void,
		some: u32
	},
	delay: u32
};

// TODO PLAN flags
// -s string
// -f first n links
// -l last n links
// -d delay
// -h help
pub fn main() u8 {
	real_main() catch return 1;
	return 0;
}

fn real_main() !void {
	defer log.flush_stdout();
	errdefer log.flush_stderr();

	var aw = AllocatorWrapper.init();
	defer aw.deinit();
	const allocator = aw.allocator();

	const args = try std.process.argsAlloc(allocator);
	defer std.process.argsFree(allocator, args);

	try arguments.validate(args[1..]);
	try run.run(args[1..]);
}
