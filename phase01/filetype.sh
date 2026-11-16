#!/usr/bin/env bash

# Accept path from first argument or prompt if omitted
target="${1:-}"
if [[ -z "$target" ]]; then
    read -rp "Enter a path to check: " target
fi

# Exit if still empty
if [[ -z "$target" ]]; then
    printf "Error: No path provided.\n" >&2
    exit 1
fi

# Check in exact order: symlink -> directory -> regular file -> other/missing
if [[ -L "$target" ]]; then
    printf "%s is a symbolic link\n" "$target"
elif [[ -d "$target" ]]; then
    printf "%s is a directory\n" "$target"
elif [[ -f "$target" ]]; then
    printf "%s is a regular file\n" "$target"
elif [[ -e "$target" ]]; then
    printf "%s exists, but is a special file (socket, pipe, or device)\n" "$target"
else
    printf "%s is missing (does not exist)\n" "$target"
fi
