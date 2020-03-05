//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#ifdef __APPLE__
typedef __signed__ char __s8;
typedef unsigned char __u8;
typedef __signed__ short __s16;
typedef unsigned short __u16;
typedef __signed__ int __s32;
typedef unsigned int __u32;
#else
    #include <linux/types.h>
#endif
#include "i2c-dev.h"

