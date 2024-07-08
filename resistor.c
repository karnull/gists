#include <stdio.h>
#include <string.h>

struct Band {
    char *color;
    int rgb[3];
};

void print_box(int rgb[])
{
    printf("\033[38;2;%d;%d;%dm󰝤\033[0m", rgb[0], rgb[1], rgb[2]);
}

void print_space(char *word) 
{
    int len = strlen(word);

    while (len < 7) {
        printf(" ");
        len += 1;
    }
}

int get_value(char *input, struct Band *bands) {
    int i = 0;
    for (i = 0; i < 10; i++) {
        if (strcmp(bands[i].color, input) == 0) {
            return i;
        }
    }
    return -1;
}

int main(int argc, char *argv[])
{
    struct Band bands[] = {
        {"black",  {0x00, 0x00, 0x00}},
        {"brown",  {0xA5, 0x2A, 0x2A}},
        {"red",    {0xFF, 0x00, 0x00}},
        {"orange", {0xFF, 0xA5, 0x00}},
        {"yellow", {0xFF, 0xFF, 0x00}},
        {"green",  {0x00, 0x80, 0x00}},
        {"blue",   {0x00, 0x00, 0xFF}},
        {"violet", {0xEE, 0x82, 0xEE}},
        {"grey",   {0x80, 0x80, 0x80}},
        {"white",  {0xFF, 0xFF, 0xFF}},
        {"gold",   {0xDA, 0xA5, 0x20}},
        {"silver", {0xC0, 0xC0, 0xC0}}
        
    };

    int register_rgb[] = {0x80, 0x80, 0x80};

    int i = 0;
    int value = 0;
    int tolerance = 0;
    int tolerance_index = -1;
    int multiplier = 0;

    switch (argc) {
        case 1:
            printf("            digit muliplier tolerance\n");
            for (i = 0; i < 10; i++) {
               // print the register table
               printf("%s ", bands[i].color);
               print_space(bands[i].color);
               print_box(bands[i].rgb);
               printf("     %d     10e%d", i, i);

               if (i == 1 || i == 2) {
                    printf("      \u00B1 %d%%", i);
               }
               printf("\n");
            }

            for (i = 10; i < 12; i++) {
                // print the register table
                printf("%s ", bands[i].color);
                print_space(bands[i].color);
                print_box(bands[i].rgb);
                printf("           10e%d     \u00B1 %d%%\n", (9-i), 5*(i-10));
            }
            break;

        case 5:
            int tolerances[] = { 1, 2, 10, 11 };
            int tolerances_values[] = { 1, 2, 5, 10 };

            for (i = 0; i < 4; i++) {
                if (strcmp(argv[4], bands[tolerances[i]].color) == 0) {
                    tolerance = tolerances_values[i];
                    tolerance_index = tolerances[i];
                }
            }

        case 4:
            printf("─");
            print_box(register_rgb);

            int single_value;
            for (i = 1; i < 4; i++) {
                single_value = get_value(argv[i], bands);
                if (single_value == -1) {
                    printf("Invalid Colors\n");
                    return 1;
                }

                print_box(bands[single_value].rgb);
                print_box(register_rgb);

                if (i == 1) {
                    value = single_value * 10;
                } else if (i == 2) {
                    value += single_value;
                } else {
                    multiplier = single_value;
                }
            }
            print_box(register_rgb);
            if (tolerance_index != -1) {
                print_box(bands[tolerance_index].rgb);
            }
            print_box(register_rgb);
            printf("─  ");

            printf("%de%d\u03A9 \u00B1%d\%\n", value, multiplier, tolerance);

            break;

        default:
            printf("Invalid Syntax. Enter colours for all bands.\n");
            break;
    }

    return 0;
}
