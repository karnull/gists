#!/usr/bin/env bash

# Wrapper around Docker commands to standardise devcontainer development.
# The main Git worktree is used to build the canonical VS Code devcontainer
# image. Linked worktrees reuse that image while mounting their own source
# directory at /workspaces/<main-project-name>.

COMMANDS_FILE=".commands"
ACTION="${1:-}"

if [ "$#" -gt 0 ]; then
    shift
fi

#-------------------------------------------------------------------------------
# Colours

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

#-------------------------------------------------------------------------------
# Move to the current worktree root

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    cd "$(git rev-parse --show-toplevel)" || exit 1
fi

CURRENT_WORKTREE="$PWD"

#-------------------------------------------------------------------------------
# Default behaviour

if [ -z "$ACTION" ]; then
    lazydocker
    exit 0
fi

show_help() {
    cat <<'EOF'
Usage: d [action] [args...]

Actions:
  up              start or create the devcontainer
  down            stop the devcontainer
  restart         restart the devcontainer
  delete          delete the devcontainer
  exec <CMD>      run CMD in the devcontainer
  connect         open a Bash shell in the devcontainer
  copilot         run copilot-cli
  generate        generate a generic .commands file
  list            list Docker containers
  image           print the shared devcontainer image

Default:
  <no action>     open lazydocker

Other:
  <action>        run an entry from the .commands file

Worktree behaviour:
  - VS Code builds the image from the main Git worktree.
  - Linked worktrees reuse the main worktree's image.
  - The current worktree is mounted at /workspaces/<main-project-name>.
  - Each worktree receives its own persistent container.
EOF
}

#-------------------------------------------------------------------------------
# Git/worktree helpers

get_main_worktree() {
    local main_worktree

    main_worktree="$(
        git worktree list --porcelain 2>/dev/null |
            sed -n 's/^worktree //p' |
            head -n1
    )"

    if [ -n "$main_worktree" ]; then
        printf '%s\n' "$main_worktree"
    else
        printf '%s\n' "$CURRENT_WORKTREE"
    fi
}

get_main_project_name() {
    basename "$(get_main_worktree)"
}

get_current_project_name() {
    basename "$CURRENT_WORKTREE"
}

is_linked_worktree() {
    local main_worktree
    local current_worktree

    main_worktree="$(cd "$(get_main_worktree)" 2>/dev/null && pwd -P)"
    current_worktree="$(cd "$CURRENT_WORKTREE" 2>/dev/null && pwd -P)"

    [ "$main_worktree" != "$current_worktree" ]
}

#-------------------------------------------------------------------------------
# Docker helpers

get_container_name() {
    local project_name

    project_name="$(get_current_project_name)"
    printf '%s-devcontainer\n' "$project_name"
}

get_main_container_name() {
    local project_name

    project_name="$(get_main_project_name)"
    printf '%s-devcontainer\n' "$project_name"
}

get_workspace_path() {
    local project_name

    project_name="$(get_main_project_name)"
    printf '/workspaces/%s\n' "$project_name"
}

container_exists() {
    docker container inspect "$1" >/dev/null 2>&1
}

container_running() {
    [ "$(docker container inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]
}

find_shared_image() {
    local project_name
    local image

    project_name="$(get_main_project_name)"

    image="$(
        docker image ls --format '{{.Repository}}:{{.Tag}}' |
            awk -v prefix="vsc-${project_name}-" '
                index($0, prefix) == 1 {
                    print
                    exit
                }
            '
    )"

    printf '%s\n' "$image"
}

open_main_worktree_in_vscode() {
    local main_worktree

    main_worktree="$(get_main_worktree)"

    printf "${YELLOW}! No shared devcontainer image was found${RESET}\n"
    printf "${BLUE}! Opening VS Code on the main worktree:${RESET} %s\n" \
        "$main_worktree"

    code "$main_worktree"
}

require_shared_image() {
    local image

    image="$(find_shared_image)"

    if [ -z "$image" ]; then
        open_main_worktree_in_vscode
        return 1
    fi

    printf '%s\n' "$image"
}

create_worktree_container() {
    local container_name
    local image
    local workspace_path
    local history_file
    local -a docker_args

    container_name="$(get_container_name)"
    image="$(require_shared_image)" || return 1
    workspace_path="$(get_workspace_path)"
    history_file="${CURRENT_WORKTREE}/.devcontainer/.bash_history"

    mkdir -p "${CURRENT_WORKTREE}/.devcontainer"
    touch "$history_file"

    docker_args=(
        run
        --detach
        --interactive
        --tty
        --name "$container_name"
        --hostname "$container_name"
        --privileged
        --device-cgroup-rule "c 189:* rmw"
        --device-cgroup-rule "c 166:* rmw"
        --device-cgroup-rule "c 188:* rmw"
        --mount "type=bind,source=${CURRENT_WORKTREE},target=${workspace_path}"
        --mount "type=bind,source=/dev,target=/dev"
        --mount "type=bind,source=/tmp/.X11-unix,target=/tmp/.X11-unix"
        --mount "type=bind,source=/etc/localtime,target=/etc/localtime,readonly"
        --mount "type=bind,source=/etc/timezone,target=/etc/timezone,readonly"
        --mount "type=bind,source=${history_file},target=/home/user/.bash_history"
        --env "DISPLAY=unix:0"
        --env "TERM=${TERM:-xterm-256color}"
        --workdir "$workspace_path"
    )

    if [ -f /opt/pclp/pclp-subscription.lic ]; then
        docker_args+=(
            --mount "type=bind,source=/opt/pclp/pclp-subscription.lic,target=/opt/pclp/pclp-subscription.lic,readonly"
        )
    fi

    docker_args+=(
        "$image"
        /bin/bash
    )

    printf "${BLUE}> Creating %s from %s${RESET}\n" \
        "$container_name" "$image"

    docker "${docker_args[@]}"
}

start_container() {
    local container_name

    container_name="$(get_container_name)"

    if container_exists "$container_name"; then
        if container_running "$container_name"; then
            printf "${GREEN}! Container is already running:${RESET} %s\n" \
                "$container_name"
        else
            printf "${BLUE}> Starting %s${RESET}\n" "$container_name"
            docker container start "$container_name"
        fi

        return 0
    fi

    if is_linked_worktree; then
        create_worktree_container
        return $?
    fi

    printf "${YELLOW}! No existing container named %s${RESET}\n" \
        "$container_name"
    printf "${BLUE}! Opening VS Code to build the canonical devcontainer image${RESET}\n"

    code "$CURRENT_WORKTREE"
}

ensure_container_running() {
    local container_name

    container_name="$(get_container_name)"

    if ! container_exists "$container_name"; then
        start_container || return 1
    elif ! container_running "$container_name"; then
        docker container start "$container_name" >/dev/null
    fi

    container_running "$container_name"
}

stop_container() {
    local container_name

    container_name="$(get_container_name)"

    if ! container_exists "$container_name"; then
        printf "${YELLOW}! Container does not exist:${RESET} %s\n" \
            "$container_name"
        return 0
    fi

    if ! container_running "$container_name"; then
        printf "${GREEN}! Container is already stopped:${RESET} %s\n" \
            "$container_name"
        return 0
    fi

    docker container stop "$container_name"
}

delete_container() {
    local container_name

    container_name="$(get_container_name)"

    if ! container_exists "$container_name"; then
        printf "${YELLOW}! Container does not exist:${RESET} %s\n" \
            "$container_name"
        return 0
    fi

    docker container rm --force "$container_name"
}

#-------------------------------------------------------------------------------
# Special commands

case "$ACTION" in
    start|up)
        start_container
        exit $?
        ;;

    stop|down)
        stop_container
        exit $?
        ;;

    restart|r)
        stop_container || exit 1
        start_container
        exit $?
        ;;

    delete|rm)
        delete_container
        exit $?
        ;;

    exec|e)
        if [ "$#" -eq 0 ]; then
            printf "${RED}Error: no command provided${RESET}\n"
            exit 1
        fi

        ensure_container_running || exit 1

        CONTAINER_NAME="$(get_container_name)"
        WORKSPACE_PATH="$(get_workspace_path)"

        docker exec \
            --user 1000 \
            --workdir "$WORKSPACE_PATH" \
            "$CONTAINER_NAME" \
            /bin/bash -lc "$*"

        exit $?
        ;;

    connect|c)
        ensure_container_running || exit 1

        CONTAINER_NAME="$(get_container_name)"
        WORKSPACE_PATH="$(get_workspace_path)"

        docker exec \
            --interactive \
            --tty \
            --user 1000 \
            --workdir "$WORKSPACE_PATH" \
            "$CONTAINER_NAME" \
            /bin/bash -l

        exit $?
        ;;

    image|img)
        IMAGE="$(find_shared_image)"

        if [ -z "$IMAGE" ]; then
            printf "${YELLOW}No shared devcontainer image found${RESET}\n"
            exit 1
        fi

        printf '%s\n' "$IMAGE"
        exit 0
        ;;

    copilot|cc)
        ensure_container_running || exit 1

        CONTAINER_NAME="$(get_container_name)"
        WORKSPACE_PATH="$(get_workspace_path)"

        docker exec \
            --interactive \
            --tty \
            --user 1000 \
            --workdir "$WORKSPACE_PATH" \
            "$CONTAINER_NAME" \
            copilot

        exit $?
        ;;

    generate|gen)
        cat > "$COMMANDS_FILE" <<'EOF'
# Project-specific commands
#
# Examples:
# build='west build'
# test='pytest $@'
EOF
        printf "${GREEN}Created %s${RESET}\n" "$COMMANDS_FILE"
        exit 0
        ;;

    list|l|ls)
        docker container ls --all \
            --format "table {{.ID}}\t{{.RunningFor}}\t{{.Status}}\t{{.Names}}"
        exit 0
        ;;

    --help|-h|help|h)
        show_help
        exit 0
        ;;
esac

#-------------------------------------------------------------------------------
# Fallback: execute an entry from .commands

if [ ! -f "$COMMANDS_FILE" ]; then
    printf "${RED}Commands file not found:${RESET} %s\n" "$COMMANDS_FILE"
    exit 1
fi

RAW_COMMAND="$(
    awk -F "'" -v action="$ACTION" '
        $0 ~ "^" action "[[:space:]]*=" {
            print $2
            exit
        }
    ' "$COMMANDS_FILE"
)"

if [ -z "$RAW_COMMAND" ]; then
    printf "${RED}Unknown action:${RESET} %s\n" "$ACTION"
    exit 1
fi

if [[ "$RAW_COMMAND" == *'$@'* ]]; then
    COMMAND="${RAW_COMMAND//\$@/$*}"
else
    COMMAND="$RAW_COMMAND"

    if [ "$#" -gt 0 ]; then
        COMMAND="$COMMAND $*"
    fi
fi

printf "${BLUE}> %s${RESET}\n" "$COMMAND"

if is_linked_worktree; then
    ensure_container_running || exit 1

    CONTAINER_NAME="$(get_container_name)"
    WORKSPACE_PATH="$(get_workspace_path)"

    docker exec \
        --interactive \
        --user 1000 \
        --workdir "$WORKSPACE_PATH" \
        "$CONTAINER_NAME" \
        /bin/bash -lc "$COMMAND"
else
    eval "$COMMAND"
fi
