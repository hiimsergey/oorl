const std = @import("std");
const arguments = @import("arguments.zig");
const log = @import("log.zig");
const run = @import("run.zig");

const AllocatorWrapper = @import("allocator.zig").AllocatorWrapper;

pub fn main() u8 {
	real_main() catch return 1;
	return 0;
}

fn real_main() !void {
	defer log.flush_stdout();
	errdefer log.flush_stderr();

	var aw = AllocatorWrapper.init();
	defer aw.deinit();
	const gpa = aw.allocator();

	const args = try std.process.argsAlloc(gpa);
	defer std.process.argsFree(gpa, args);

	try arguments.validate(args[1..]);
	try run.run_args(args[1..]);
}
