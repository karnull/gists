#!/usr/bin/env bash

git log --graph \
    --pretty=format:"%d%C(yellow)%h%Creset %s" \
    --decorate --abbrev-commit --color=always $@ \
| awk '{
    if ($0 ~ /^[[:space:]]*\*[[:space:]]+\(.*\).*/) {
        line = $0

        indent = line
        sub(/\*.*/, "", indent)

        inner = line
        sub(/^[^(]*\(/, "", inner)
        sub(/\).*$/, "", inner)

        suffix = line
        sub(/^[^(]*\([^)]*\)/, "", suffix)

        if (!seen) {
            seen = 1
        } else {
            print ""
        }

        printf " \033[34m(%s)\033[0m\n", inner
        print indent "* " suffix

    } else {
        print
    }
}' | nl -w4 -s' ' -b p'^[[:space:]]*\* '
``
