#include "kernel.h"

#define VIDEO_MEMORY 0xb8000

void kernel_main(){
    unsigned char *video = (unsigned char *)VIDEO_MEMORY;
    video[0] = 'H';
    video[2] = 'i';
}