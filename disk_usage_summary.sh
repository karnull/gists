#!?usr/bin/env bash

set -euo pipefail
TARGET="${1:-.}"
TOPN="${2:-10}"

du -x -h "$TARGET" 2>/dev/null | sort -hr |head -n "$TOPN"

echo
echo "Total for $TARGET:"
du -x -sh "$TARGET" 2>/dev/null

