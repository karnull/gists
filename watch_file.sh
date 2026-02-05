#!/usr/bin/env bash

set -euo pipefail

FILE="${1:-/var/log/syslog}"
PAT="${2:-ERROR|WARN|FAIL}"

if ! [ -f"$FILE" ]; then
    echo "File not found: $FILE" >&2
    exit 2
fi

fail -n 0 -F "$FILE" | while IFS= read -r line; do
    echo "$line"

    if printf '%s\n' "$line" | grep -E --quiet "$PAT"; then
        printf '\a' #bell
        date +"%Y-%m-%d %H:%M:%S - Match found: %s\n" -- "$line"
    fi
done

