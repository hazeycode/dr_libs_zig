const std = @import("std");
const log = std.log.scoped(.dr_libs_zig);

pub const wav = @import("wav.zig");
pub const mp3 = @import("mp3.zig");

pub fn init(allocator: std.mem.Allocator) void {
    std.debug.assert(mem_allocator == null);
    mem_allocator = allocator;
    mem_allocations = std.AutoHashMap(usize, usize).init(allocator);
    dr_libs_malloc = malloc;
    dr_libs_realloc = realloc;
    dr_libs_free = free;
    dr_libs_copy = copy;
    dr_libs_assert = assert;
}

pub fn deinit() void {
    std.debug.assert(mem_allocator != null);
    std.debug.assert(mem_allocations.?.count() == 0);
    mem_allocations.?.deinit();
    mem_allocations = null;
    mem_allocator = null;
}

var mem_allocator: ?std.mem.Allocator = null;
var mem_allocations: ?std.AutoHashMap(usize, usize) = null;
var mem_mutex: std.Thread.Mutex = .{};
const mem_alignment = 16;

extern var dr_libs_malloc: ?*const fn (usize) callconv(.C) ?*anyopaque;
extern var dr_libs_realloc: ?*const fn (?*anyopaque, usize) callconv(.C) ?*anyopaque;
extern var dr_libs_free: ?*const fn (?*anyopaque) callconv(.C) void;
extern var dr_libs_copy: ?*const fn (?*anyopaque, ?*anyopaque, usize) callconv(.C) void;
extern var dr_libs_assert: ?*const fn (c_int) callconv(.C) void;

fn malloc(size: usize) callconv(.C) ?*anyopaque {
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const mem = mem_allocator.?.alignedAlloc(
        u8,
        mem_alignment,
        size,
    ) catch |err| {
        log.err("alignedAlloc failed with error {s}", .{@errorName(err)});
        return null;
    };

    mem_allocations.?.put(@ptrToInt(mem.ptr), size) catch |err| {
        log.err("malloc: failed to record allocation with error {s}", .{@errorName(err)});
    };

    return mem.ptr;
}

fn realloc(ptr: ?*anyopaque, size: usize) callconv(.C) ?*anyopaque {
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const old_size = if (ptr != null) mem_allocations.?.get(@ptrToInt(ptr.?)).? else 0;
    const old_mem = if (old_size > 0)
        @ptrCast([*]align(mem_alignment) u8, @alignCast(mem_alignment, ptr))[0..old_size]
    else
        @as([*]align(mem_alignment) u8, undefined)[0..0];

    const new_mem = mem_allocator.?.realloc(old_mem, size) catch |err| {
        log.err("realloc failed with error {s}", .{@errorName(err)});
        return null;
    };

    if (ptr != null) {
        const removed = mem_allocations.?.remove(@ptrToInt(ptr.?));
        std.debug.assert(removed);
    }

    mem_allocations.?.put(@ptrToInt(new_mem.ptr), size) catch |err| {
        log.err("realloc: failed to record allocation with error {s}", .{@errorName(err)});
    };

    return new_mem.ptr;
}

fn free(maybe_ptr: ?*anyopaque) callconv(.C) void {
    if (maybe_ptr) |ptr| {
        mem_mutex.lock();
        defer mem_mutex.unlock();

        const size = mem_allocations.?.fetchRemove(@ptrToInt(ptr)).?.value;
        const mem = @ptrCast([*]align(mem_alignment) u8, @alignCast(mem_alignment, ptr))[0..size];
        mem_allocator.?.free(mem);
    }
}

fn copy(maybe_dst_ptr: ?*anyopaque, maybe_src_ptr: ?*anyopaque, size: usize) callconv(.C) void {
    std.mem.copy(
        u8,
        @ptrCast([*]u8, maybe_dst_ptr)[0..size],
        @ptrCast([*]u8, maybe_src_ptr)[0..size],
    );
}

fn assert(condition: c_int) callconv(.C) void {
    std.debug.assert(condition != 0);
}

test {
    _ = std.testing.refAllDecls(@This());
}
