#ifndef MEMORYLATENCY_H
#define MEMORYLATENCY_H

#include <stdint.h>

#if __cplusplus
extern "C" {
#endif

float RunLatencyTest(uint32_t size_kb, uint32_t iterations);
float RunAsmLatencyTest(uint32_t size_kb, uint32_t iterations);

int SetLargePages(uint32_t enabled);

#if __cplusplus
} // extern "C"
#endif
#endif // MEMORYLATENCY_H
