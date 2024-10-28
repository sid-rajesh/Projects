// bmp_steganography.h
#ifndef BMP_STEGANOGRAPHY_H
#define BMP_STEGANOGRAPHY_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

// BMP and DIB headers
#pragma pack(1)
typedef struct {
    char format[2];
    uint32_t size;
    uint16_t reserved1;
    uint16_t reserved2;
    uint32_t offset;
} BMPHeader;

typedef struct {
    uint32_t size;
    int32_t width;
    int32_t height;
    uint16_t planes;
    uint16_t bits_per_pixel;
    uint32_t compression;
    uint32_t image_size;
    int32_t x_resolution;
    int32_t y_resolution;
    uint32_t colors;
    uint32_t important_colors;
} DIBHeader;

typedef struct {
    uint8_t blue;
    uint8_t green;
    uint8_t red;
} Pixel;

#pragma pack(4)



// Function declarations
void read_headers(FILE *file, BMPHeader *bmp_header, DIBHeader *dib_header);
void display_info(const BMPHeader *bmp_header, const DIBHeader *dib_header);
void reveal_image(FILE *file, const BMPHeader *bmp_header, const DIBHeader *dib_header);
void hide_image(FILE *file1, FILE *file2, const BMPHeader *bmp_header, const DIBHeader *dib_header);

#endif
