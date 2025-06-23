#!/bin/bash
#
# This script recursively scans a specified directory and renames all files
# and subdirectories to produce "clean" names. It removes unwanted patterns
# (such as text in square [ ] or round ( ) brackets), replaces dots (.)
# with spaces (except before file extensions), and trims extra spaces.
# Expected Input:
#   - A single argument: the path to the target directory to clean.
#   - Optional second argument: "-s" for silent mode (applies changes without
#     confirmation and suppresses most output).

# Check for path argument
if [[ -z "$1" ]]; then
    echo "No directory specified. Usage: $0 /path/to/target"
    exit 1
fi

target="$1"
silent_mode=false

# Check if silent mode flag (-s) is provided
if [[ "$2" == "-s" ]]; then
    silent_mode=true
fi

# Validate directory
if [[ ! -d "$target" ]]; then
    echo "\"$target\" is not a valid directory."
    exit 1
fi

clean_name() {
    local name="$1"
    # Remove [...] and (...)
    name=$(echo "$name" | sed -E 's/\[[^]]*\]//g; s/\([^)]*\)//g')
    # Remove extra spaces
    name=$(echo "$name" | sed -E 's/ +/ /g; s/^ //; s/ $//')
    # Replace . with space, except before file extension
    if [[ "$name" == *.* ]]; then
        ext="${name##*.}"
        base="${name%.*}"
        base=$(echo "$base" | sed -E 's/\./ /g')
        name="$base.$ext"
    else
        name=$(echo "$name" | sed -E 's/\./ /g')
    fi
    echo "$name"
}

# If not in silent mode, print the proposed changes
if ! $silent_mode; then
    echo -e "Proposed changes in: \"$target\"\n"
fi

changes=()

# Loop through all files and directories to gather changes
while IFS= read -r -d '' item; do
    base=$(basename "$item")
    dir=$(dirname "$item")
    cleaned=$(clean_name "$base")
    if [[ "$base" != "$cleaned" ]]; then
        if ! $silent_mode; then
            echo "\"$item\" → \"$dir/$cleaned\""
        fi
        changes+=("$item|$dir/$cleaned")
    fi
done < <(find "$target" -depth -print0)

# Silent mode: Automatically apply changes without asking
if $silent_mode; then
    for change in "${changes[@]}"; do
        src="${change%%|*}"
        dest="${change##*|}"
        if [[ -e "$dest" ]]; then
            if ! $silent_mode; then
                echo "❗ Skipping \"$src\" → \"$dest\" (already exists)"
            fi
        else
            mv -v "$src" "$dest"
        fi
    done
else
    # Ask for confirmation in normal mode
    echo
    read -p "Do you want to apply these changes? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for change in "${changes[@]}"; do
            src="${change%%|*}"
            dest="${change##*|}"
            if [[ -e "$dest" ]]; then
                echo "❗ Skipping \"$src\" → \"$dest\" (already exists)"
            else
                mv -v "$src" "$dest"
            fi
        done
    else
        echo "No changes applied."
    fi
fi
