const std = @import("std");

pub const HeadBuffer = struct {
	buf: [][]const u8,
	head: usize,

	fn init(gpa: std.mem.Allocator, size: u32) std.mem.Allocator.Error!HeadBuffer {
		return .{
			.buf = try gpa.alloc([]const u8, size),
			.head = 0
		};
	}

	fn deinit(self: *HeadBuffer, gpa: std.mem.Allocator) void {
		gpa.free(self.buf);
	}

	fn add(self: *HeadBuffer, item: []const u8) void {
		self.buf[self.head] = item;
		self.head += 1;
	}
};
pub const RingBuffer = struct {
	buf: [][]const u8,
	head: usize,
	got_full: bool,

	fn init(gpa: std.mem.Allocator, size: u32) std.mem.Allocator.Error!RingBuffer {
		std.debug.assert(size > 0);
		return .{
			.buf = try gpa.alloc([]const u8, size),
			.head = 0,
			.got_full = false
		};
	}

	fn add(self: *RingBuffer, item: []const u8) void {
		self.buf[self.head] = item;
		self.head = @mod(self.head + 1, self.buf.len);
		self.got_full = self.got_full or self.head == 0;
	}

	fn deinit(self: *RingBuffer, gpa: std.mem.Allocator) void {
		gpa.free(self.buf);
	}
};
