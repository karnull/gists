#!/usr/bin/env bash

# Add .worktrees/ to your global gitignore, or the main checkout sees every worktree as untracked
WORKTREE_DIR="./.worktrees/"

#- Helper Functions --------------------------------------------------------------------------------

die() {
    echo "git: $*" >&2
    exit 1
}

# The main worktree is always listed first, even when run from inside a linked one
cd_root() {
    local root
    root=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
    [[ -n $root ]] || exit 1
    cd "$root" || die "cannot enter $root"
}

# Stands in for mapfile -t, which the bash 3.2 shipped with macOS lacks
read_lines() {
    local line
    eval "$1=()"
    while IFS= read -r line; do
        eval "$1+=(\"\$line\")"
    done
}

pick() {
    command -v fzf > /dev/null || die "fzf is not installed"
    fzf --height=40% --border=rounded --preview-window=right:65% "$@"
}

pick_branch() {
    pick --preview 'git log --oneline --decorate --color=always -n 50 {}' "$@"
}

local_branches() {
    git for-each-ref --format='%(refname:short)' refs/heads
}

remote_branches() {
    git for-each-ref --format='%(refname:lstrip=2)' refs/remotes | grep -v '/HEAD$'
}

all_branches() {
    local_branches
    remote_branches
}

is_local() {
    git show-ref --verify --quiet "refs/heads/$1"
}

# Fetches origin/feature/x into a local feature/x that tracks it, unless one exists already
make_local() {
    local remote=${1%%/*} name=${1#*/}
    is_local "$name" && return
    git fetch --quiet "$remote" "$name" && git branch --quiet --track "$name" "$1"
}

# Prints the local name for a picked branch, making a local copy of a remote one first
as_local() {
    if is_local "$1"; then
        echo "$1"
    else
        make_local "$1" && echo "${1#*/}"
    fi
}

# refs/remotes/<remote>/HEAD only exists after a clone or set-head, so ask the remote when it is missing
remote_default() {
    local head
    if head=$(git symbolic-ref --quiet --short "refs/remotes/$1/HEAD"); then
        echo "${head#"$1"/}"
        return
    fi

    head=$(GIT_TERMINAL_PROMPT=0 git ls-remote --symref "$1" HEAD 2> /dev/null \
        | awk '$1 == "ref:" && $3 == "HEAD" { sub("^refs/heads/", "", $2); print $2 }')
    if [[ -n $head ]]; then
        echo "$head"
    else
        printf '%s\n' main master
    fi
}

# Current branch and each remote's default branch, local copy included
protected_branches() {
    local remote branch
    git branch --show-current
    git remote | while IFS= read -r remote; do
        remote_default "$remote" | while IFS= read -r branch; do
            printf '%s\n%s\n' "$remote/$branch" "$branch"
        done
    done
}


#- Worktrees ---------------------------------------------------------------------------------------

worktree_add() {
    cd_root

    local branch name
    while IFS= read -r branch; do
        name=$(as_local "$branch") || continue
        git worktree add "$WORKTREE_DIR$(tr / - <<< "$name")" "$name"
    done < <(all_branches | pick_branch --multi --prompt='worktree add > ')
}

worktree_check() {
    cd_root

    local branch
    while IFS= read -r branch; do
        git worktree add --detach "$WORKTREE_DIR$(tr / - <<< "$branch")" "$branch"
    done < <(remote_branches | pick_branch --multi --prompt='worktree check > ')
}

worktree_delete() {
    local all=0
    case $1 in
        --all) all=1 ;;
        '')    ;;
        *)     die "worktree_delete: unknown option $1" ;;
    esac

    cd_root

    local -a trees
    read_lines trees < <(git worktree list --porcelain | sed -n 's/^worktree //p' | tail -n +2)
    (( ${#trees[@]} )) || return 0
    (( all )) || read_lines trees < <(printf '%s\n' "${trees[@]}" | pick --multi --prompt='worktree remove > ' \
        --preview 'git -C {} log --oneline --decorate --color=always -n 50')

    local tree
    for tree in "${trees[@]}"; do
        git worktree remove "$tree"
    done
}


#- Branches ----------------------------------------------------------------------------------------

branch_switch() {
    local branch name
    branch=$(all_branches | pick_branch --prompt='switch > ') || return 0
    name=$(as_local "$branch") && git switch "$name"
}

branch_check() {
    local branch
    branch=$(remote_branches | pick_branch --prompt='check > ') || return 0
    git switch --detach "$branch"
}

branch_local() {
    local branch
    while IFS= read -r branch; do
        make_local "$branch"
    done < <(
        remote_branches | while IFS= read -r branch; do
            is_local "${branch#*/}" || echo "$branch"
        done | pick_branch --multi --prompt='make local > '
    )
}

branch_delete() {
    local all=0 delete=-d arg
    for arg in "$@"; do
        case $arg in
            --all) all=1 ;;
            -f)    delete=-D ;;
            *)     die "branch_delete: unknown option $arg" ;;
        esac
    done

    local source=all_branches
    (( all )) && source=local_branches

    local -a branches
    read_lines branches < <("$source" | grep -vxFf <(protected_branches))
    (( ${#branches[@]} )) || return 0

    if (( all )); then
        printf '  %s\n' "${branches[@]}"
        read -rp "Delete these ${#branches[@]} branches? [y/N] " arg
        [[ $arg == [yY] ]] || return 0
    else
        read_lines branches < <(printf '%s\n' "${branches[@]}" | pick_branch --multi --prompt='branch delete > ')
    fi

    local branch
    for branch in "${branches[@]}"; do
        if is_local "$branch"; then
            git branch "$delete" "$branch"
        else
            git push "${branch%%/*}" --delete "${branch#*/}"
        fi
    done
}


#- Rebase ------------------------------------------------------------------------------------------

rebase_branch() {
    local branch
    branch=$(all_branches | grep -vxF "$(git branch --show-current)" | pick_branch --prompt='rebase onto > ') \
        || return 0
    git rebase "$branch"
}


#- Stashes -----------------------------------------------------------------------------------------

# Prints only the stash@{n} of each picked line
pick_stash() {
    local picked
    picked=$(git stash list --format='%gd %s' | pick --preview 'git stash show --color=always {1}' "$@") || return
    cut -d' ' -f1 <<< "$picked"
}

stash_pop() {
    local stash
    stash=$(pick_stash --prompt='stash pop > ') || return 0
    git stash pop "$stash"
}

# Highest index first, since each drop renumbers the stashes above it
stash_drop() {
    local stash
    while IFS= read -r stash; do
        git stash drop "$stash"
    done < <(pick_stash --multi --prompt='stash drop > ' | sort -t'{' -k2 -nr)
}


#- Entry Point -------------------------------------------------------------------------------------

COMMANDS=(worktree_add worktree_check worktree_delete branch_switch branch_check branch_local branch_delete rebase_branch stash_pop stash_drop)

usage() {
    cat << EOF
usage: ${0##*/} <command> [options]

  worktree_add                 add a worktree for each picked branch
  worktree_check               add a detached worktree for each picked remote branch, without fetching
  worktree_delete [--all]      remove the picked linked worktrees, or all of them
  branch_switch                switch to the picked branch
  branch_check                 check out the picked remote branch detached, without fetching
  branch_local                 make local copies of the picked remote branches
  branch_delete [--all] [-f]   delete the picked branches, or every local one; -f forces
  rebase_branch                rebase the current branch onto the picked one
  stash_pop                    apply and remove the picked stash
  stash_drop                   delete the picked stashes
EOF
}

case $1 in
    '')        usage >&2; exit 1 ;;
    -h|--help) usage; exit 0 ;;
esac

cmd=$1
shift

if [[ " ${COMMANDS[*]} " == *" $cmd "* ]]; then
    "$cmd" "$@"
else
    echo "git: ${cmd}: command not found" >&2
    usage >&2
    exit 127
fi

#---------------------------------------------------------------------------------------------------
