#!/bin/bash
# This script performs a targeted backup of defined system and user data from an android device to a mounted device. (Such as an external HDD, SSD or USB device)
# configuration files.
# It uses rsync for efficient, incremental copying,
# applies exclusions to skip unnecessary files, and maintains logs of
# backup operations and installed software.
# This will prompt you for a mount to select, this works only of ROFI is installed and if the device isn't mounted yet.

# CONFIGURATION

MOUNT_POINT="/mnt/android"
BACKUP_DRIVE="/mnt/backup_drive"
BACKUP_TARGET="$BACKUP_DRIVE/backup_phone"
LOG_DIR="$HOME/Documents/backup_logs"
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
RUN_LOG="$LOG_DIR/backup_phone_$NOW.log"

ANDROID_ITEMS=(
    "Internal shared storage/DCIM/"
    "Internal shared storage/Pictures/"
    "Internal shared storage/Android/media/"
    "....."
)

mkdir -p "$LOG_DIR"

# --- External HDD Mounting Logic ---
# List available partitions not currently mounted, let user select
DEVICE=$(lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT |     awk '$3 == "part" && $4 == "" {print $1, $2}' |     sed 's/^[^/dev]*//' |     rofi -dmenu -p "Select backup partition" |     awk '{print $1}'
/dev/sdb1)


if [ -z "$DEVICE" ]; then
    echo "No device selected. Exiting."
    exit 1
fi

echo "Selected device: $DEVICE"

# Check if already mounted, else mount it
if ! mount | grep -q "$BACKUP_DRIVE"; then
    sudo mkdir -p "$BACKUP_DRIVE"
    sudo mount "$DEVICE" "$BACKUP_DRIVE"
    if [ $? -ne 0 ]; then
        echo "Failed to mount $DEVICE. Exiting."
        exit 2
    fi
fi

echo "External HDD mounted at $BACKUP_DRIVE"

sudo mkdir -p "$BACKUP_TARGET"

# Ask for password and mount with doas if not already mounted
if ! mount | grep -q "$MOUNT_POINT"; then
    echo "Mounting Android device at $MOUNT_POINT (requires password for doas/jmtpfs)..."
    doas mkdir -p "$MOUNT_POINT"
    doas chown "$USER":"$USER" "$MOUNT_POINT"
    doas jmtpfs -o allow_other "$MOUNT_POINT"
    sleep 1
    if ! mount | grep -q "$MOUNT_POINT"; then
        echo "Failed to mount Android device. Exiting."
        exit 2
    fi
fi

echo "Android device mounted at $MOUNT_POINT"

# --- Backup Logic ---
for SRC in "${ANDROID_ITEMS[@]}"; do
    SRC_PATH="$MOUNT_POINT/$SRC"
    if [ -d "$SRC_PATH" ]; then
        echo "Backing up: $SRC_PATH" | tee -a "$RUN_LOG"
        sudo rsync -avh --progress --relative "$SRC_PATH" "$BACKUP_TARGET" | tee -a "$RUN_LOG"
    else
        echo "Warning: $SRC_PATH not found, skipping." | tee -a "$RUN_LOG"
    fi
done

sync

# Unmount the Android device
echo "Unmounting Android device..."
doas fusermount -u "$MOUNT_POINT"

echo "Android backup complete. Log saved to $RUN_LOG"
