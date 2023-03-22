const std = @import("std");

const wchar_t = c_int;
const drmp3_int8 = i8;
const drmp3_uint8 = u8;
const drmp3_int16 = c_short;
const drmp3_uint16 = c_ushort;
const drmp3_int32 = c_int;
const drmp3_uint32 = c_uint;
const drmp3_int64 = c_longlong;
const drmp3_uint64 = c_ulonglong;
const drmp3_uintptr = drmp3_uint64;
const drmp3_bool8 = drmp3_uint8;
const drmp3_bool32 = drmp3_uint32;
const drmp3_result = drmp3_int32;

pub const TRUE = @as(c_int, 1);
pub const FALSE = @as(c_int, 0);
pub const SUCCESS = @as(c_int, 0);
pub const ERROR = -@as(c_int, 1);

pub const MAX_PCM_FRAMES_PER_MP3_FRAME = @as(c_int, 1152);
pub const MAX_SAMPLES_PER_FRAME = MAX_PCM_FRAMES_PER_MP3_FRAME * @as(c_int, 2);

pub const SeekOrigin = enum(c_uint) {
    start,
    current,
};

pub const Mp3Config = extern struct {
    channels: drmp3_uint32,
    sampleRate: drmp3_uint32,
};

pub const Mp3 = extern struct {
    decoder: Mp3Dec,
    channels: drmp3_uint32,
    sampleRate: drmp3_uint32,
    onRead: ReadProc,
    onSeek: SeekProc,
    pUserData: ?*anyopaque,
    allocationCallbacks: AllocationCallbacks,
    mp3FrameChannels: drmp3_uint32,
    mp3FrameSampleRate: drmp3_uint32,
    pcmFramesConsumedInMP3Frame: drmp3_uint32,
    pcmFramesRemainingInMP3Frame: drmp3_uint32,
    pcmFrames: [@sizeOf(f32) * MAX_SAMPLES_PER_FRAME]drmp3_uint8,
    currentPCMFrame: drmp3_uint64,
    streamCursor: drmp3_uint64,
    pSeekPoints: ?*SeekPoint,
    seekPointCount: drmp3_uint32,
    dataSize: usize,
    dataCapacity: usize,
    dataConsumed: usize,
    pData: *drmp3_uint8,
    atEnd: drmp3_uint32, // atEnd is defined as the first flag in a C bitfield
    memory: extern struct {
        pData: *drmp3_uint8,
        dataSize: usize,
        currentReadPos: usize,
    },
};

pub const Mp3Dec = extern struct {
    mdct_overlap: [2][288]f32,
    qmf_state: [960]f32,
    reserv: c_int,
    free_format_bytes: c_int,
    header: [4]drmp3_uint8,
    reserv_buf: [511]drmp3_uint8,
};

pub const ReadProc = ?*const fn (?*anyopaque, ?*anyopaque, usize) callconv(.C) usize;

pub const SeekProc = ?*const fn (?*anyopaque, c_int, c_uint) callconv(.C) drmp3_bool32;

pub const AllocationCallbacks = extern struct {
    pUserData: ?*anyopaque,
    onMalloc: ?*const fn (usize, ?*anyopaque) callconv(.C) ?*anyopaque,
    onRealloc: ?*const fn (?*anyopaque, usize, ?*anyopaque) callconv(.C) ?*anyopaque,
    onFree: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.C) void,
};

pub const SeekPoint = extern struct {
    seekPosInBytes: drmp3_uint64,
    pcmFrameIndex: drmp3_uint64,
    mp3FramesToDiscard: drmp3_uint16,
    pcmFramesToDiscard: drmp3_uint16,
};

pub fn initMemory(bytes: []const u8) ?Mp3 {
    var mp3: Mp3 = undefined;
    if (drmp3_init_memory(&mp3, bytes.ptr, bytes.len, null) == FALSE) {
        return null;
    }
    return mp3;
}
extern fn drmp3_init_memory(
    pMP3: ?*Mp3,
    pData: ?*const anyopaque,
    dataSize: usize,
    pAllocationCallbacks: [*c]const AllocationCallbacks,
) drmp3_bool32;

pub fn uninit(mp3: *Mp3) void {
    return drmp3_uninit(mp3);
}
extern fn drmp3_uninit(pMP3: ?*Mp3) void;

pub fn readPcmFramesS16(mp3: *Mp3, frames_to_read: u64, out_buffer: []i16) u64 {
    const bytes_to_read = mp3.channels * @sizeOf(f32) * frames_to_read;
    const out_buffer_bytes = out_buffer.len / @sizeOf(i16);
    std.debug.assert(out_buffer_bytes >= bytes_to_read);
    return drmp3_read_pcm_frames_s16(mp3, frames_to_read, out_buffer.ptr);
}
extern fn drmp3_read_pcm_frames_s16(
    pMP3: ?*Mp3,
    framesToRead: drmp3_uint64,
    pBufferOut: [*c]drmp3_int16,
) drmp3_uint64;

pub fn readPcmFramesF32(mp3: *Mp3, frames_to_read: u64, out_buffer: []f32) u64 {
    const bytes_to_read = mp3.channels * @sizeOf(f32) * frames_to_read;
    const out_buffer_bytes = out_buffer.len / @sizeOf(f32);
    std.debug.assert(out_buffer_bytes >= bytes_to_read);
    return drmp3_read_pcm_frames_f32(mp3, frames_to_read, out_buffer.ptr);
}
extern fn drmp3_read_pcm_frames_f32(
    pMP3: ?*Mp3,
    framesToRead: drmp3_uint64,
    pBufferOut: [*c]f32,
) drmp3_uint64;

pub fn openMemoryAndReadPcmFramesF32(
    bytes: []const u8,
    out_config: *Mp3Config,
    out_frame_count: *u64,
) [*]f32 {
    return drmp3_open_memory_and_read_pcm_frames_f32(
        bytes.ptr,
        bytes.len,
        out_config,
        out_frame_count,
        null,
    );
}
extern fn drmp3_open_memory_and_read_pcm_frames_f32(
    pData: ?*const anyopaque,
    dataSize: usize,
    pConfig: [*c]Mp3Config,
    pTotalFrameCount: [*c]drmp3_uint64,
    pAllocationCallbacks: [*c]const AllocationCallbacks,
) [*c]f32;

test {
    _ = std.testing.refAllDecls(@This());
}
