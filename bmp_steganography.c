#include "bmp_steganography.h"
#include <string.h>
#include <stdlib.h>

void read_headers(FILE *file, BMPHeader *bmp_header, DIBHeader *dib_header) {
    fread(bmp_header, sizeof(BMPHeader), 1, file);
    fread(dib_header, sizeof(DIBHeader), 1, file);

    // Validate BMP format
    if (bmp_header->format[0] != 'B' || bmp_header->format[1] != 'M') {
        printf("ERROR: The format is not supported.\n");
        exit(1);
    }

    // Validate DIB header size
    if (dib_header->size != 40) {
        printf("ERROR: The format is not supported.\n");
        exit(1);
    }

    // Validate bits per pixel
    if (dib_header->bits_per_pixel != 24) {
        printf("ERROR: The format is not supported.\n");
        exit(1);
    }
}

//displaying info 
void display_info(const BMPHeader *bmp_header, const DIBHeader *dib_header) {
    printf("=== BMP Header ===\n");
    printf("Type: %c%c\n", bmp_header->format[0], bmp_header->format[1]);
    printf("Size: %u\n", bmp_header->size);
    printf("Reserved 1: %u\n", bmp_header->reserved1);
    printf("Reserved 2: %u\n", bmp_header->reserved2);
    printf("Image offset: %u\n", bmp_header->offset);

    printf("\n=== DIB Header ===\n");
    printf("Size: %u\n", dib_header->size);
    printf("Width: %d\n", dib_header->width);
    printf("Height: %d\n", dib_header->height);
    printf("# color planes: %u\n", dib_header->planes);
    printf("# bits per pixel: %u\n", dib_header->bits_per_pixel);
    printf("Compression scheme: %u\n", dib_header->compression);
    printf("Image size: %u\n", dib_header->image_size);
    printf("Horizontal resolution: %d\n", dib_header->x_resolution);
    printf("Vertical resolution: %d\n", dib_header->y_resolution);
    printf("# colors in palette: %u\n", dib_header->colors);
    printf("# important colors: %u\n", dib_header->important_colors);
}

//code to reveal image
void reveal_image(FILE *file, const BMPHeader *bmp_header, const DIBHeader *dib_header) {
    fseek(file, bmp_header->offset, SEEK_SET);

    int width = dib_header->width;
    int height = dib_header->height;

    Pixel pixel;
    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            fread(&pixel, sizeof(pixel), 1, file);

            // Swap the 4 MSB and 4 LSB
            pixel.blue = (pixel.blue << 4) | (pixel.blue >> 4);
            pixel.green = (pixel.green << 4) | (pixel.green >> 4);
            pixel.red = (pixel.red << 4) | (pixel.red >> 4);

            fseek(file, -sizeof(pixel), SEEK_CUR);
            fwrite(&pixel, sizeof(pixel), 1, file);
        }
        int padding = (4 - (width * 3) % 4) % 4;
        fseek(file, padding, SEEK_CUR);
    }
}

void hide_image(FILE *file1, FILE *file2, const BMPHeader *bmp_header, const DIBHeader *dib_header) {
    fseek(file1, bmp_header->offset, SEEK_SET);
    fseek(file2, bmp_header->offset, SEEK_SET);

    int width = dib_header->width;
    int height = dib_header->height;

    Pixel pixel1, pixel2;
    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            fread(&pixel1, sizeof(Pixel), 1, file1);
            fread(&pixel2, sizeof(Pixel), 1, file2);

            // Hide the 4 MSB of pixel2 in the 4 LSB of pixel1
            pixel1.blue = (pixel1.blue & 0xF0) | (pixel2.blue >> 4);
            pixel1.green = (pixel1.green & 0xF0) | (pixel2.green >> 4);
            pixel1.red = (pixel1.red & 0xF0) | (pixel2.red >> 4);

            fseek(file1, -sizeof(Pixel), SEEK_CUR);
            fwrite(&pixel1, sizeof(Pixel), 1, file1);
        }
        int padding = (4 - (width * 3) % 4) % 4;
        fseek(file1, padding, SEEK_CUR);
        fseek(file2, padding, SEEK_CUR);
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("ERROR: Missing arguments.\n");
        return 1;
    }

    FILE *file1 = fopen(argv[2], "rb+");
    if (!file1) {
        printf("ERROR: Could not open file %s\n", argv[2]);
        return 1;
    }

    BMPHeader bmp_header;
    DIBHeader dib_header;
    read_headers(file1, &bmp_header, &dib_header);

    if (strcmp(argv[1], "--info") == 0) {
        display_info(&bmp_header, &dib_header);
    } else if (strcmp(argv[1], "--reveal") == 0) {
        reveal_image(file1, &bmp_header, &dib_header);
    } else if (strcmp(argv[1], "--hide") == 0 && argc == 4) {
        FILE *file2 = fopen(argv[3], "rb");
        if (!file2) {
            printf("ERROR: Could not open file %s\n", argv[3]);
            fclose(file1);
            return 1;
        }
        hide_image(file1, file2, &bmp_header, &dib_header);
        fclose(file2);
    } else {
        printf("Invalid option or missing second file.\n");
    }

    fclose(file1);
    return 0;
}
