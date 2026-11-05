#!/bin/bash

#- Process script flags ----------------------------------------------------------------------------

CONVERT_FILE=false

if [[ "$1" == "-c" || "$1" == "--convert" ]]; then
    CONVERT_FILE=true
    shift
elif [[ "${!#}" == "-c" || "${!#}" == "--convert" ]]; then
    CONVERT_FILE=true
    set -- "${@:1:$(($#-1))}"
fi

#- Record original file names ----------------------------------------------------------------------

# keep the name list in RAM-backed storage where the system has it
BUFFER_DIR="${XDG_RUNTIME_DIR:-/dev/shm}"
[[ -d "$BUFFER_DIR" && -w "$BUFFER_DIR" ]] || BUFFER_DIR="${TMPDIR:-/tmp}"

RENAME_BUFFER=$(mktemp "${BUFFER_DIR%/}/namedit.XXXXXX") || {
    echo -e "Failed to create temp file";
    exit 1;
}
mv "$RENAME_BUFFER" "$RENAME_BUFFER.toml"
RENAME_BUFFER="$RENAME_BUFFER.toml"
trap 'rm -f "$RENAME_BUFFER"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

echo "# Mass Rename Tool
# - Dont add new lines or delete existing ones
# - Rename with "DELETE" to delete the said files (macro @x)
# - Dont shuffle file order
"> "$RENAME_BUFFER" || {
    echo -e "Failed to create $RENAME_BUFFER";
    exit 1;
}

ORIGINAL_NAMES=()

if [ $# -eq 0 ]; then
    for arg in *; do
        echo -e "$arg" >> "$RENAME_BUFFER"
        ORIGINAL_NAMES+=("$arg")
    done
else
    for arg in "$@"; do
        clean_arg="${arg#./}"
        echo -e "$clean_arg" >> "$RENAME_BUFFER"
        ORIGINAL_NAMES+=("$clean_arg")
    done
fi

LINES_BEFORE=$(wc -l < "$RENAME_BUFFER" | tr -d ' ')


#- Compare original against new names---------------------------------------------------------------

$EDITOR "$RENAME_BUFFER"

# read loop rather than mapfile, which the bash 3.2 shipped with macOS lacks
NEW_LINES=()
while IFS= read -r line || [[ -n "$line" ]]; do
    NEW_LINES+=("$line")
done < "$RENAME_BUFFER"
rm "$RENAME_BUFFER"

LINES_AFTER=${#NEW_LINES[@]}

if [ "$LINES_BEFORE" != "$LINES_AFTER" ]; then
    echo -e "\033[31mError:\033[0m Name list mismatch"
    exit 1
fi

for (( i=6; i<=$LINES_BEFORE; i++ )); do
    original_name="${ORIGINAL_NAMES[$i-6]}"
    new_name="${NEW_LINES[$i-1]}"

    # do nothing if filename isn't changed
    if [[ "$original_name" == "$new_name" ]]; then
        continue

    # delete file if new name is just DELETE
    elif [ "$new_name" = "DELETE" ]; then
        echo -e "\033[31mDeleting \033[36m$original_name"
        rm -rf "./$original_name"

    # if the file extensions are the same or convert is false
    elif [[ "${original_name##*.}" == "${new_name##*.}" ||
        "$new_name" == "${new_name%.*}" ||
        "$original_name" == "${original_name%.*}" ||
        "$CONVERT_FILE" == false ]]; then
        echo -e "\033[33mRenaming \033[36m$original_name \033[33mto \033[0m$new_name"
        mv "./$original_name" "./$new_name"

    # check if ffmpeg is installed
    elif ! command -v ffmpeg &> /dev/null; then
        echo -e "\033[31mError:\033[0m Install ffmpeg to perform filetype conversions."
        echo -e "\033[33mRenaming \033[36m$original_name \033[33mto \033[0m${new_name%.*}.${original_name##*.}"
        mv "./$original_name" "./${new_name%.*}.${original_name##*.}"

    # convert file
    else
        echo -e "\033[33mConverting \033[36m$original_name \033[33mto \033[0m$new_name"
        ffmpeg -i "$original_name" "$new_name" -loglevel warning

        # check if ffmpeg was successful
        if [ $? -eq 0 ]; then
            rm "$original_name"
        else
            echo -e "\033[31mError:\033[0m Conversion failed for $original_name"
        fi
    fi
done

