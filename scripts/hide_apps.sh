#!/bin/bash

# --- CONFIGURATION ---
# Comma-separated list of apps to find (e.g., "skype,thunderbird,update-notifier")
echo "Enter the names of the apps/files you want to disable (separated by commas):"
read -r user_input

# Convert comma-separated string to an array
IFS=',' read -ra SEARCH_TERMS <<< "$user_input"

# Target Directories
USER_APP_DIR="$HOME/.local/share/applications"
USER_AUTO_DIR="$HOME/.config/autostart"

# Ensure directories exist
mkdir -p "$USER_APP_DIR"
mkdir -p "$USER_AUTO_DIR"

process_files() {
    local src_dir=$1
    local dest_dir=$2
    local term=$3
    local hide_flag=$4

    # Find files matching the term (case-insensitive)
    find "$src_dir" -maxdepth 1 -iname "*${term}*.desktop" 2>/dev/null | while read -r sys_file; do
        filename=$(basename "$sys_file")
        dest_file="$dest_dir/$filename"

        echo "Processing: $filename"

        # Copy to user directory
        cp "$sys_file" "$dest_file"

        # Remove existing hide/hidden flags to avoid duplicates
        sed -i "/^NoDisplay=/d" "$dest_file"
        sed -i "/^Hidden=/d" "$dest_file"

        # Add the appropriate disable flag
        echo "$hide_flag=true" >> "$dest_file"

        echo "  [✓] Copied to $dest_dir and disabled."
    done
}

# Iterate through the terms provided by the user
for term in "${SEARCH_TERMS[@]}"; do
    # Trim whitespace from the term
    term=$(echo "$term" | xargs)

    if [ -z "$term" ]; then continue; fi

    echo "Searching for '$term'..."

    # Process Application Menu entries
    process_files "/usr/share/applications" "$USER_APP_DIR" "$term" "NoDisplay"

    # Process Autostart entries
    process_files "/etc/xdg/autostart" "$USER_AUTO_DIR" "$term" "Hidden"
done

echo "Done! You may need to restart your desktop session for all changes to take effect."
