#!/bin/bash

# check arguments or piped input
if [ "$#" -lt 1 ]; then
    echo -e "\033[31mMissing Arguments\033[0m"
    echo -e "Usage: \033[33mvimacro.sh \033[35m<input> <macro>"
    exit 1
fi

# if input is from stdin or arguments
if [ -t 0 ]; then
    # no piped input
    # use the first argument as input and the second as vim commands
    input="$1"
    vi_commands="$2"
else
    # use piped input
    input=$(cat)
    vi_commands="$1"
fi

output=$(echo "$input" |
    vi -E -s -u NONE -c "%norm "$vi_commands"" -c "wq! /dev/stdout" /dev/stdin
)

# print result
echo "$output"

