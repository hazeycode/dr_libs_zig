const std = @import("std");

const wchar_t = c_int;
const drwav_int8 = i8;
const drwav_uint8 = u8;
const drwav_int16 = c_short;
const drwav_uint16 = c_ushort;
const drwav_int32 = c_int;
const drwav_uint32 = c_uint;
const drwav_int64 = c_longlong;
const drwav_uint64 = c_ulonglong;
const drwav_uintptr = drwav_uint64;
const drwav_bool8 = drwav_uint8;
const drwav_bool32 = drwav_uint32;
const drwav_result = drwav_int32;

pub const TRUE = @as(c_int, 1);
pub const FALSE = @as(c_int, 0);
pub const SUCCESS = @as(c_int, 0);
pub const ERROR = -@as(c_int, 1);

const Wav = extern struct {
    onRead: ReadProc,
    onWrite: WriteProc,
    onSeek: SeekProc,
    pUserData: ?*anyopaque,
    allocationCallbacks: AllocationCallbacks,
    container: c_uint,
    fmt: Fmt,
    sampleRate: drwav_uint32,
    channels: drwav_uint16,
    bitsPerSample: drwav_uint16,
    translatedFormatTag: drwav_uint16,
    totalPCMFrameCount: drwav_uint64,
    dataChunkDataSize: drwav_uint64,
    dataChunkDataPos: drwav_uint64,
    bytesRemaining: drwav_uint64,
    readCursorInPCMFrames: drwav_uint64,
    dataChunkDataSizeTargetWrite: drwav_uint64,
    isSequentialWrite: drwav_bool32,
    allowedMetadataTypes: MetadataType,
    pMetadata: [*c]Metadata,
    metadataCount: drwav_uint32,
    memoryStream: MemoryStream,
    memoryStreamWrite: MemoryStreamWrite,
    msadpcm: extern struct {
        bytesRemainingInBlock: drwav_uint32,
        predictor: [2]drwav_uint16,
        delta: [2]drwav_int32,
        cachedFrames: [4]drwav_int32,
        cachedFrameCount: drwav_uint32,
        prevFrames: [2][2]drwav_int32,
    },
    ima: extern struct {
        bytesRemainingInBlock: drwav_uint32,
        predictor: [2]drwav_int32,
        stepIndex: [2]drwav_int32,
        cachedFrames: [16]drwav_int32,
        cachedFrameCount: drwav_uint32,
    },
};

const ReadProc = ?*const fn (?*anyopaque, ?*anyopaque, usize) callconv(.C) usize;

const WriteProc = ?*const fn (
    ?*anyopaque,
    ?*const anyopaque,
    usize,
) callconv(.C) usize;

const SeekProc = ?*const fn (?*anyopaque, c_int, c_uint) callconv(.C) drwav_bool32;

const ChunkProc = ?*const fn (
    ?*anyopaque,
    ReadProc,
    SeekProc,
    ?*anyopaque,
    ?*const ChunkHeader,
    c_uint,
    ?*const Fmt,
) callconv(.C) drwav_uint64;

const ChunkHeader = extern struct {
    id: extern union {
        fourcc: [4]drwav_uint8,
        guid: [16]drwav_uint8,
    },
    sizeInBytes: drwav_uint64,
    paddingSize: c_uint,
};

pub const Container = enum(c_uint) {
    riff,
    w64,
    rf64,
};

pub const SeekOrigin = enum(c_uint) {
    start,
    current,
};

pub const AllocationCallbacks = extern struct {
    pUserData: ?*anyopaque,
    onMalloc: ?*const fn (usize, ?*anyopaque) callconv(.C) ?*anyopaque,
    onRealloc: ?*const fn (?*anyopaque, usize, ?*anyopaque) callconv(.C) ?*anyopaque,
    onFree: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.C) void,
};

pub const Fmt = extern struct {
    formatTag: drwav_uint16,
    channels: drwav_uint16,
    sampleRate: drwav_uint32,
    avgBytesPerSec: drwav_uint32,
    blockAlign: drwav_uint16,
    bitsPerSample: drwav_uint16,
    extendedSize: drwav_uint16,
    validBitsPerSample: drwav_uint16,
    channelMask: drwav_uint32,
    subFormat: [16]drwav_uint8,
};

pub const MetadataType = enum(c_int) {
    none = 0,
    unknown = 1,
    smpl = 2,
    inst = 4,
    cue = 8,
    acid = 16,
    bext = 32,
    list_label = 64,
    list_note = 128,
    list_labelled_cue_region = 256,
    list_info_software = 512,
    list_info_copyright = 1024,
    list_info_title = 2048,
    list_info_artist = 4096,
    list_info_comment = 8192,
    list_info_date = 16384,
    list_info_genre = 32768,
    list_info_album = 65536,
    list_info_tracknumber = 131072,
    list_all_info_strings = 261632,
    list_all_adtl = 448,
    all = -2,
    all_including_unknown = -1,
};

pub const Metadata = extern struct {
    type: MetadataType,
    data: extern union {
        cue: Cue,
        smpl: Smpl,
        acid: Acid,
        inst: Inst,
        bext: Bext,
        labelOrNote: LabelOrNote,
        labelledCueRegion: LabelledCueRegion,
        infoText: ListInfoText,
        unknown: UnknownMetadata,
    },
};

pub const CuePoint = extern struct {
    id: drwav_uint32,
    playOrderPosition: drwav_uint32,
    dataChunkId: [4]drwav_uint8,
    chunkStart: drwav_uint32,
    blockStart: drwav_uint32,
    sampleByteOffset: drwav_uint32,
};

pub const Cue = extern struct {
    cuePointCount: drwav_uint32,
    pCuePoints: [*c]CuePoint,
};

pub const SmplLoopType = enum(c_uint) {
    forward,
    pingpong,
    backward,
};

pub const SmplLoop = extern struct {
    cuePointId: drwav_uint32,
    type: SmplLoopType,
    firstSampleByteOffset: drwav_uint32,
    lastSampleByteOffset: drwav_uint32,
    sampleFraction: drwav_uint32,
    playCount: drwav_uint32,
};

pub const Smpl = extern struct {
    manufacturerId: drwav_uint32,
    productId: drwav_uint32,
    samplePeriodNanoseconds: drwav_uint32,
    midiUnityNote: drwav_uint32,
    midiPitchFraction: drwav_uint32,
    smpteFormat: drwav_uint32,
    smpteOffset: drwav_uint32,
    sampleLoopCount: drwav_uint32,
    samplerSpecificDataSizeInBytes: drwav_uint32,
    pLoops: [*c]SmplLoop,
    pSamplerSpecificData: [*c]drwav_uint8,
};

pub const Acid = extern struct {
    flags: drwav_uint32,
    midiUnityNote: drwav_uint16,
    reserved1: drwav_uint16,
    reserved2: f32,
    numBeats: drwav_uint32,
    meterDenominator: drwav_uint16,
    meterNumerator: drwav_uint16,
    tempo: f32,
};

pub const Inst = extern struct {
    midiUnityNote: drwav_int8,
    fineTuneCents: drwav_int8,
    gainDecibels: drwav_int8,
    lowNote: drwav_int8,
    highNote: drwav_int8,
    lowVelocity: drwav_int8,
    highVelocity: drwav_int8,
};

pub const Bext = extern struct {
    pDescription: [*:0]u8,
    pOriginatorName: [*:0]u8,
    pOriginatorReference: [*:0]u8,
    pOriginationDate: [10]u8,
    pOriginationTime: [8]u8,
    timeReference: drwav_uint64,
    version: drwav_uint16,
    pCodingHistory: [*:0]u8,
    codingHistorySize: drwav_uint32,
    pUMID: [*c]drwav_uint8,
    loudnessValue: drwav_uint16,
    loudnessRange: drwav_uint16,
    maxTruePeakLevel: drwav_uint16,
    maxMomentaryLoudness: drwav_uint16,
    maxShortTermLoudness: drwav_uint16,
};

pub const LabelOrNote = extern struct {
    cuePointId: drwav_uint32,
    stringLength: drwav_uint32,
    pString: [*:0]u8,
};

pub const LabelledCueRegion = extern struct {
    cuePointId: drwav_uint32,
    sampleLength: drwav_uint32,
    purposeId: [4]drwav_uint8,
    country: drwav_uint16,
    language: drwav_uint16,
    dialect: drwav_uint16,
    codePage: drwav_uint16,
    stringLength: drwav_uint32,
    pString: [*:0]u8,
};

pub const ListInfoText = extern struct {
    stringLength: drwav_uint32,
    pString: [*:0]u8,
};

pub const MetadataLocation = enum(c_uint) {
    invalid,
    top_level,
    inside_info_list,
    inside_adtl_list,
};

pub const UnknownMetadata = extern struct {
    id: [4]drwav_uint8,
    chunkLocation: MetadataLocation,
    dataSizeInBytes: drwav_uint32,
    pData: [*c]drwav_uint8,
};

pub const MemoryStream = extern struct {
    data: [*c]const drwav_uint8,
    dataSize: usize,
    currentReadPos: usize,
};

pub const MemoryStreamWrite = extern struct {
    ppData: [*c]?*anyopaque,
    pDataSize: [*c]usize,
    dataSize: usize,
    dataCapacity: usize,
    currentWritePos: usize,
};

pub fn initMemory(bytes: []const u8) ?Wav {
    var wav: Wav = undefined;
    if (drwav_init_memory(&wav, bytes.ptr, bytes.len, null) == FALSE) {
        return null;
    }
    return wav;
}
extern fn drwav_init_memory(
    pWav: *Wav,
    data: ?*const anyopaque,
    dataSize: usize,
    pAllocationCallbacks: [*c]const AllocationCallbacks,
) drwav_bool32;

pub fn uninit(wav: *Wav) bool {
    return drwav_uninit(wav) == SUCCESS;
}
extern fn drwav_uninit(pWav: *Wav) drwav_result;

pub fn readPcmFrames(wav: *Wav, frames_to_read: u64, out_buffer: []u8) u64 {
    std.debug.assert(out_buffer.len >= wav.bitsPerSample / 8 * wav.channels * frames_to_read);
    return drwav_read_pcm_frames(wav, frames_to_read, out_buffer.ptr);
}
extern fn drwav_read_pcm_frames(
    pWav: [*c]Wav,
    framesToRead: drwav_uint64,
    pBufferOut: ?*anyopaque,
) drwav_uint64;

pub fn openMemoryAndReadPcmFramesF32(
    bytes: []const u8,
    out_channels: *u32,
    out_sample_rate: *u32,
    out_frame_count: *u64,
) [*]f32 {
    return drwav_open_memory_and_read_pcm_frames_f32(
        bytes.ptr,
        bytes.len,
        out_channels,
        out_sample_rate,
        out_frame_count,
        null,
    );
}
extern fn drwav_open_memory_and_read_pcm_frames_f32(
    data: ?*const anyopaque,
    dataSize: usize,
    channelsOut: [*c]c_uint,
    sampleRateOut: [*c]c_uint,
    totalFrameCountOut: [*c]drwav_uint64,
    pAllocationCallbacks: [*c]const AllocationCallbacks,
) [*c]f32;

test {
    _ = std.testing.refAllDecls(@This());
}
