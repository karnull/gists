#!/usr/bin/env bash

set -euo pipefail

if command -v ss >/dev/null 2>&1; then
    ss -tulpen | awk 'NR==1{print;next}/LISTEN/||/udp/ {print}'
elif command -v netstat >/dev/null 2>&1; then
    netstat -tulpen
else
    echo "Require ss or netstat" >&2
    exit 1
fi

