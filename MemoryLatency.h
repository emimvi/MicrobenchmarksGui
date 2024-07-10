#ifndef MEMORYLATENCY_H
#define MEMORYLATENCY_H

#include <stdint.h>

#if __cplusplus
extern "C" {
#endif

float RunTest(uint32_t size_kb, uint32_t iterations, uint32_t *preallocatedArr);

uint32_t* preallocate_arr(uint32_t size_kb);
void free_preallocate_arr(uint32_t *preallocatedArr, uint32_t size_kb);

#if __cplusplus
} // extern "C"
#endif
#endif // MEMORYLATENCY_H
