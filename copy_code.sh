#!/bin/bash

# Initialise arrays
DIRS=()        # For arguments that start with a dot
EXTENSIONS=()  # For arguments that do not start with a dot

# Temporary file buffer
CATBUFFER=".__copy_buffer__"
touch $CATBUFFER

# Loop through all arguments
for arg in "$@"; do
    if [[ $arg == .* ]]; then
        DIRS+=( "$arg" )
    else
        EXTENSIONS+=( "-iname" "*.$arg" "-o" )
    fi
done

if [ ${#DIRS[@]} -eq 0 ]; then
    DIRS+=( "." )
fi

# Loop through all directories
for dir in "${DIRS[@]}"; do
    # remove trailing '-o' if present
    if [ ${#EXTENSIONS[@]} -gt 0 ]; then
        if [ ${EXTENSIONS[${#EXTENSIONS[@]}-1]} = "-o" ]; then
            EXTENSIONS=("${EXTENSIONS[@]:0:${#EXTENSIONS[@]}-1}")
        fi

        # find files based on constructed conditions, excluding .git directory
        find "$dir" -type f          \
            \( "${EXTENSIONS[@]}" \) \
            -not -path './build/*'   \
            -not -path '*/.*'        \
            -exec sh -c              \
                'for file; do echo "======================[ $file ]======================" \
                >> "$0"; cat "$file" >> "$0"; done' "$CATBUFFER" {} +

    else
        find "$dir" -type f          \
            -not -path './build/*'   \
            -not -path '*/.*'        \
            -exec sh -c              \
                'for file; do echo "======================[ $file ]======================" \
                >> "$0"; cat "$file" >> "$0"; done' "$CATBUFFER" {} +
    fi
done

# Remove temporary file buffer
cat $CATBUFFER | pbcopy
rm $CATBUFFER

