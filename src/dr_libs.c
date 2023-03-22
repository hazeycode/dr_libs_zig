#include <stdlib.h>

void* (*dr_libs_malloc)(size_t size) = NULL;
void* (*dr_libs_realloc)(void* ptr, size_t size) = NULL;
void (*dr_libs_free)(void* ptr) = NULL;
void (*dr_libs_copy)(void*, void*, size_t) = NULL;
void (*dr_libs_assert)(int) = NULL;

#define DRWAV_MALLOC(size) dr_libs_malloc(size)
#define DRWAV_REALLOC(ptr, size) dr_libs_realloc(ptr, size)
#define DRWAV_FREE(ptr) dr_libs_free(ptr)
#define DRWAV_COPY_MEMORY(dst, src, sz) dr_libs_copy(dst, src, sz)
#define DRWAV_ASSERT(condition) dr_libs_assert(condition);

#define DR_WAV_IMPLEMENTATION
#define DR_WAV_NO_STDIO
#include "dr_wav.h"

#define DRMP3_MALLOC(size) dr_libs_malloc(size)
#define DRMP3_REALLOC(ptr, size) dr_libs_realloc(ptr, size)
#define DRMP3_FREE(ptr) dr_libs_free(ptr)
#define DRMP3_COPY_MEMORY(dst, src, sz) dr_libs_copy(dst, src, sz)
#define DRMP3_ASSERT(condition) dr_libs_assert(condition);

#define DR_MP3_IMPLEMENTATION
#define DR_MP3_NO_STDIO
#include "dr_mp3.h"
