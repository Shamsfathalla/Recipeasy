#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int page_number;
    unsigned char age_counter;
} PageFrame;

void aging_algorithm(int frame_count, int *page_references, int reference_count) {
    PageFrame *frames = (PageFrame *)malloc(frame_count * sizeof(PageFrame));
    for (int i = 0; i < frame_count; i++) {
        frames[i].page_number = -1;
        frames[i].age_counter = 0;
    }

    int page_fault_count = 0;
    for (int i = 0; i < reference_count; i++) {
        int current_page = page_references[i];
        int page_found = 0;

        // Check if the page is already in one of the frames
        for (int j = 0; j < frame_count; j++) {
            if (frames[j].page_number == current_page) {
                frames[j].age_counter |= 0x80; // Set the MSB to 1
                page_found = 1;
                break;
            }
        }

        // If the page is not found, replace the least recently used page
        if (!page_found) {
            page_fault_count++;
            int oldest_frame_index = 0;
            for (int j = 1; j < frame_count; j++) {
                if (frames[j].age_counter < frames[oldest_frame_index].age_counter) {
                    oldest_frame_index = j;
                }
            }
            frames[oldest_frame_index].page_number = current_page;
            frames[oldest_frame_index].age_counter = 0x80; // Set the MSB to 1
        }

        // Shift the age bits to the right for all frames
        for (int j = 0; j < frame_count; j++) {
            frames[j].age_counter >>= 1;
        }
    }

    printf("Total page faults: %d\n", page_fault_count);
    free(frames);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <num_frames> <input_file>\n", argv[0]);
        return 1;
    }

    int frame_count = atoi(argv[1]);
    char *input_file = argv[2];

    FILE *file = fopen(input_file, "r");
    if (file == NULL) {
        perror("Error opening file");
        return 1;
    }

    int page_references[10000];
    int reference_count = 0;
    while (fscanf(file, "%d", &page_references[reference_count]) != EOF) {
        reference_count++;
    }
    fclose(file);

    aging_algorithm(frame_count, page_references, reference_count);

    return 0;
}