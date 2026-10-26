#!/bin/zsh

# ==============================================================================
# SCRIPT NAME: backup.command
# DESCRIPTION: Compresses a specified folder into a timestamped .zip archive
#              and saves it to an external or local destination directory.
# PLATFORM:    macOS (Apple Silicon & Intel) using /bin/zsh
# AUTHOR:      Sergio Fonseca + Gemini AI
# ==============================================================================
#
# HOW TO USE THIS SCRIPT:
#
# 1. INITIAL SETUP (Required once):
#    Before running for the first time, grant execution permissions via Terminal:
#      chmod +x /path/to/backup.command
#
# 2. RUN FROM FINDER (GUI / Double-Click):
#    - Double-click 'backup.command' directly in Finder.
#    - When DEBUG=false: Terminal runs, notifies, and automatically closes.
#    - When DEBUG=true:  Terminal stays open so you can inspect output/errors.
#
# 3. RUN FROM TERMINAL (CLI):
#    - Default run:
#        ./backup.command
#
#    - Override parameters on the fly:
#        ./backup.command [SOURCE_DIR] [DEST_DIR] [ARCHIVE_PREFIX] [DEBUG]
#      Example (normal mode):
#        ./backup.command "/Users/sergio/Documents" "/Volumes/MyDrive/Backups" "Docs"
#      Example (debug mode):
#        ./backup.command "/Users/sergio/Documents" "/Volumes/MyDrive/Backups" "Docs" true
#
# PREREQUISITES & MACOS NOTES:
#  - Permissions: When run for the first time, macOS may request permission
#    for Terminal to access "Removable Volumes" or "OneDrive". Click "Allow".
#  - OneDrive: If files are set to "Cloud-only" (Files On-Demand), ensure they are
#    downloaded locally ("Always Keep on This Device") before archiving.
# ==============================================================================

# Enable strict error checking (stops execution on unexpected command failure)
set -e

# ==============================================================================
# CONFIGURATION PARAMETERS
# ==============================================================================
# These can be edited directly below or passed as CLI arguments: $1, $2, $3, $4

# 1. Source Folder: The directory you want to compress
SOURCE_DIR="${1:-/Users/sergiofonseca/Library/CloudStorage/OneDrive-Pessoal/Documents}"

# 2. Destination Folder: Where the final .zip file will be saved
DEST_DIR="${2:-/Volumes/APPLE2T/BACKUP/Documents}"

# 3. Archive Name Prefix: Output format will be: [PREFIX] - yyyy-MM-dd-hh-mm-ss.zip
BACKUP_NAME_PREFIX="${3:-Documents}"

# 4. Debug Mode: (false by default). Set to "true" to keep the window open & enable exit traps
DEBUG="${4:-false}"
DEBUG="${DEBUG:l}" # Convert to lowercase (accepts True, TRUE, true)

# ==============================================================================
# DEBUG & TRAP CONTROLS
# ==============================================================================

# Helper function to pause before exit (active only in debug mode)
finish_and_pause() {
    local exit_code=$?
    echo ""
    if [ $exit_code -ne 0 ]; then
        echo "❌ Process terminated with errors (Exit code: $exit_code)."
    fi
    echo "Press any key to close this window..."
    read -k 1
    exit $exit_code
}

# Enable trap ONLY when DEBUG is true
if [[ "$DEBUG" == "true" || "$DEBUG" == "1" ]]; then
    trap finish_and_pause EXIT
fi

# ==============================================================================
# VALIDATION & PREPARATION
# ==============================================================================

echo "===================================================================================================="
echo "          macOS Backup Utility (.command)         "
echo "===================================================================================================="
echo "Timestamp:    $(date '+%Y-%m-%d %H:%M:%S')"
echo "Source:       $SOURCE_DIR"
echo "Destination:  $DEST_DIR"
echo "Debug Mode:   $DEBUG"
echo "===================================================================================================="

# Step 1: Verify source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory does not exist or is inaccessible:"
    echo "   $SOURCE_DIR"
    exit 1
fi

# Step 2: If destination is on an external drive (/Volumes/...), check if mounted
if [[ "$DEST_DIR" == /Volumes/* ]]; then
    VOLUME_ROOT=$(echo "$DEST_DIR" | cut -d'/' -f1-3)
    if [ ! -d "$VOLUME_ROOT" ]; then
        echo "❌ Error: Target drive/volume is not mounted or connected:"
        echo "   $VOLUME_ROOT"
        echo "   Please plug in the external drive and try again."
        exit 1
    fi
fi

# Step 3: Ensure target destination directory exists (creates subfolders if missing)
if [ ! -d "$DEST_DIR" ]; then
    echo "📁 Creating missing destination folder: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# Step 4: Construct archive filename: "Documents - yyyy-MM-dd-hh-mm-ss.zip"
TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
ARCHIVE_NAME="${BACKUP_NAME_PREFIX} - ${TIMESTAMP}.zip"
DEST_FILE="${DEST_DIR}/${ARCHIVE_NAME}"

# ==============================================================================
# COMPRESSION PROCESS
# ==============================================================================

SOURCE_PARENT="$(dirname "$SOURCE_DIR")"
SOURCE_BASENAME="$(basename "$SOURCE_DIR")"

echo "\n📦 Archiving in progress... Please wait."

# Execute zip from parent directory so the root path is not embedded in the archive
(
    cd "$SOURCE_PARENT"
    # Options:
    #   -r : Recurse into directories
    #   -q : Quiet operation (suppresses thousands of file lines for speed)
    #   -x : Exclude invisible macOS filesystem metadata files (.DS_Store)
    zip -r -q "$DEST_FILE" "$SOURCE_BASENAME" -x "*.DS_Store"
)

# ==============================================================================
# VERIFICATION & COMPLETION
# ==============================================================================

if [ -f "$DEST_FILE" ]; then
    FILE_SIZE=$(du -sh "$DEST_FILE" | awk '{print $1}')
    
    echo "\n Backup completed successfully! 📦"
    echo "----------------------------------------------------------------------------------------------------"
    echo "File Name:    $ARCHIVE_NAME"
    echo "File Size:    $FILE_SIZE"
    echo "Saved at:     $DEST_FILE"
    echo "----------------------------------------------------------------------------------------------------"

    # Trigger native macOS Desktop Notification with sound
    osascript <<EOF
    display notification "Archive: $ARCHIVE_NAME ($FILE_SIZE)" \
        with title "Backup Complete" \
        sound name "Glass"
EOF

    # Handle window closing based on DEBUG mode
    if [[ "$DEBUG" == "true" || "$DEBUG" == "1" ]]; then
        echo "\n🐞 Debug Mode is ON: Terminal window will stay open."
        exit 0
    else
        # Automatically close the Terminal window and exit cleanly
        osascript -e 'tell application "Terminal" to close front window' &
        exit 0
    fi
else
    echo "\n❌ Error: Backup file could not be verified at destination."
    exit 1
fi