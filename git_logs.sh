#!/usr/bin/env bash

#----------------------------------------------------------------
# clipboard

copy_clipboard() {
    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy
    elif command -v clip.exe >/dev/null 2>&1; then
        clip.exe
    elif command -v wl-copy >/dev/null 2>&1; then
        wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --input
    elif command -v termux-clipboard-set >/dev/null 2>&1; then
        termux-clipboard-set
    else
        cat >/dev/null
        echo "git_logs: no clipboard utility found" >&2
        return 1
    fi
}

#----------------------------------------------------------------
# commit picker

# Prints the hash of each picked commit, newest first
pick_commits() {
    git log --graph --oneline --decorate --color=always "$@" \
        | nl -w2 -s' ' -b p'^[[:space:]]*\* ' \
        | fzf --ansi \
        | sort -n \
        | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^[0-9a-f]{7,40}$/) { print $i; next } }'
}

#----------------------------------------------------------------
# custom args

customs=""
action=""

new_args=()
for arg in "$@"; do
    case "$arg" in
        current)
            customs+="main..HEAD"
            ;;
        cp|check)
            action=$arg
            ;;
        *)
            new_args+=("$arg")
            ;;
    esac
done

set -- "${new_args[@]}"


#----------------------------------------------------------------
# git logs

if [ -n "$action" ]; then
    if ! command -v fzf >/dev/null 2>&1; then
        echo "git_logs: fzf is not installed" >&2
        exit 1
    fi

    case "$action" in
        cp)
            selected_sha=$(pick_commits "$@")
            git show -s --oneline --decorate --color=always "$selected_sha" 2>/dev/null \
                && printf '%s' "$selected_sha" | copy_clipboard
            ;;
        check)
            selected_sha=$(pick_commits "$@")
            [ -z "$selected_sha" ] || git checkout "$selected_sha"
            ;;
    esac

else
    git_log_args=()
    if [ -n "$customs" ]; then
        git_log_args+=("$customs")
    fi
    git_log_args+=("$@")

    git log --graph \
        --pretty=format:"%d%C(yellow)%h%Creset %s" \
        --decorate --abbrev-commit --color=always "${git_log_args[@]}" \
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

            } else if ($0 ~ /\*[[:space:]]+\([^)]*\)/) {
                line = $0

                match(line, /\([^)]*\)/)
                deco = substr(line, RSTART, RLENGTH)

                rest = line
                sub(/ \([^)]*\)/, "", rest)

                printf "%s \033[34m%s\033[0m\n", rest, deco

            } else {
                print
            }
        }' | nl -w4 -s' ' -b p'^[[:space:]]*\* ' | less -FRX
fi
