#!/bin/bash
# This script performs a targeted backup of defined system and user data to a mounted device. (Such as an external HDD, SSD or USB device)
# configuration files.
# It uses rsync for efficient, incremental copying,
# applies exclusions to skip unnecessary files, and maintains logs of
# backup operations and installed software.
# This will prompt you for a mount to select, this works only of ROFI is installed and if the device isn't mounted yet.


# CONFIGURATION
BACKUP_ITEMS=(
    "/etc/apt/sources.list"
    "/etc/apt/sources.list.d/"
    "/etc/hblock/allow.list"
    "/etc/hblock/deny.list"
    "/etc/hblock/sources.list"
    "/home/$USER/.config"
    "/home/$USER/.bashrc"
    "/home/$USER/.vimrc"
    "/home/$USER/.vim"
    "/home/$USER/Documents/..."
    "/home/$USER/Torrents/.torrentfiles"
    "...."
)

EXCLUDES=(
  "--exclude=/home/$USER/Documents/SomethingToIgnore/"
  "--exclude=.VirtualBoxVMs"
  "--exclude=.cache"
  "--exclude=lost+found"
  "--exclude=**/.venc/"
  "--exclude=**/.venv/"
  "--exclude=*.tmp"
  "--exclude=*.ova"
  "--exclude=*.vdi"
  "--exclude=...."
)

MAX_SIZE="50G"

# Where to mount the external drive
MOUNT_POINT="/mnt/mountpoint"

# Log directory (on your main system, not the external drive) to track backups
LOG_DIR="$HOME/Documents/backup_logs"
mkdir -p "$LOG_DIR"

DEVICE=$(lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT |     awk '$3 == "part" && $4 == "" {print $1, $2}' |     sed 's/^[^/dev]*//' |     rofi -dmenu -p "Select backup partition" |     awk '{print $1}'
/dev/sdb1)


if [ -z "$DEVICE" ]; then
    echo "No device selected. Exiting."
    exit 1
fi

echo "Selected device: $DEVICE"

# Check if already mounted, else mount it
if ! mount | grep -q "$MOUNT_POINT"; then
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount "$DEVICE" "$MOUNT_POINT"
    if [ $? -ne 0 ]; then
        echo "Failed to mount $DEVICE. Exiting."
        exit 2
    fi
fi

# Create backup target directory on the drive
BACKUP_TARGET="$MOUNT_POINT/backup"
mkdir -p "$BACKUP_TARGET"

# Timestamp for this backup
NOW=$(date +"%Y-%m-%d_%H-%M-%S")

# Log file for this run
RUN_LOG="$LOG_DIR/backup_$NOW.log"

# Rsync options: archive, verbose, itemize changes, delete, log file
for SRC in "${BACKUP_ITEMS[@]}"; do
  # Skip Files Larger Than 15GB
  # -a Archive mode
  # -A preserve Access Control Lists
  # -X Preserve extended attributes
  rsync -aAXvhP --max-size="$MAX_SIZE" --itemize-changes --stats -R "${EXCLUDES[@]}" "$SRC" "$BACKUP_TARGET" | tee -a "$RUN_LOG"
done

# Copy the log directory to the backup drive
# -a Archive mode
# -A preserve Access Control Lists
# -X Preserve extended attributes
rsync -aAXvh  "$LOG_DIR/" "$BACKUP_TARGET/backup_logs/"

apt list --installed | sort > "$BACKUP_TARGET/installed_$(date +%s).txt"

# Sync and unmount
sync

sudo umount "$MOUNT_POINT"

echo "Backup complete. Log saved to $RUN_LOG"


