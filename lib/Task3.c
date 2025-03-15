#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int page_number;
    unsigned char age_count;
} PageFrame;

void aging_alg(int frame_count, int *page_references, int reference_count) {
    PageFrame *frames = (PageFrame *)malloc(frame_count * sizeof(PageFrame));
    for (int i = 0; i < frame_count; i++) {
        frames[i].page_number = -1;
        frames[i].age_count = 0;
    }

    int page_fault_count = 0;
    for (int i = 0; i < reference_count; i++) {
        int current_page = page_references[i];
        int found = 0;
        printf("Processing page reference: %d\n", current_page);
        for (int j = 0; j < frame_count; j++) {
            if (frames[j].page_number == current_page) {
                frames[j].age_count |= 0x80;
                found = 1;
                printf("Page %d found in frame %d, age_count updated to %d\n", current_page, j, frames[j].age_count);
                break;
            }
        }
        if (!found) {
            page_fault_count++;
            int smallest_age = 0xFF;
            int smallest_age_index = 0;
            for (int k = 0; k < frame_count; k++) {
                if (frames[k].age_count < smallest_age) {
                    smallest_age = frames[k].age_count;
                    smallest_age_index = k;
                }
            }
            printf("Page %d not found, replacing page in frame %d with age_count %d\n", current_page, smallest_age_index, frames[smallest_age_index].age_count);
            frames[smallest_age_index].page_number = current_page;
            frames[smallest_age_index].age_count = 0x80;
        }
        for (int k = 0; k < frame_count; k++) {
            frames[k].age_count >>= 1;
            printf("Frame %d: page_number = %d, age_count = %d\n", k, frames[k].page_number, frames[k].age_count);
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
    FILE *input_file = fopen(argv[2], "r");
    if (input_file == NULL) {
        printf("Error opening file %s\n", argv[2]);
        return 1;
    }

    int page_references[10000];
    int reference_count = 0;
    while (fscanf(input_file, "%d", &page_references[reference_count]) != EOF) {
        reference_count++;
    }
    fclose(input_file);

    aging_alg(frame_count, page_references, reference_count);

    return 0;
}