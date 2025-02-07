#!/bin/env bash

# Delete any symbolic link with the file it redirects to

# Check if a symbolic link path is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <symbolic_link_path>"
    exit 1
fi

# Get the symbolic link path
link_path="$1"

# Check if the symbolic link exists and is a symbolic link
if [ ! -L "$link_path" ]; then
    echo "Error: $link_path is not a symbolic link"
    exit 1
fi

# Get the target file of the symbolic link
target=$(readlink -f "$link_path")

# Remove the symbolic link
rm "$link_path"
echo "Deleted $link_path"

# Check if the target file exists and is not a directory
if [ -f "$target" ]; then
    # Remove the target file
    rm "$target"
    echo "Deleted $target"
fi

