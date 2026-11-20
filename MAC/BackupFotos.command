#!/bin/zsh

# ==============================================================================
# SCRIPT NAME: BackupFotos.command
# DESCRIPTION: Compresses each selected photo subfolder into its own timestamped
#              .zip archive in an external or local destination directory.
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
#    - Double-click 'BackupFotos.command' directly in Finder.
#    - Enter folder numbers separated by spaces or commas (e.g. 1,2).
#      Press Enter without a selection to cancel.
#    - Each selected folder creates a separate ZIP: Fotos - Foldername - date.zip.
#    - When DEBUG=false: Terminal runs, notifies, and automatically closes.
#    - When DEBUG=true:  Terminal stays open so you can inspect output/errors.
#
# 3. RUN FROM TERMINAL (CLI):
#    - Default run (prompts for folders, just like Finder):
#        ./BackupFotos.command
#
#    - Override parameters on the fly:
#        ./BackupFotos.command [SOURCE_DIR] [DEST_DIR] [ARCHIVE_PREFIX] [DEBUG]
#      Example (normal mode):
#        ./BackupFotos.command "/Volumes/APPLE2T/Fotos" "/Volumes/MyDrive/Backups" "Fotos"
#      Example (debug mode):
#        ./BackupFotos.command "/Volumes/APPLE2T/Fotos" "/Volumes/MyDrive/Backups" "Fotos" true
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

# 1. Source Folder: The parent directory containing the photo subfolders
SOURCE_DIR="${1:-/Volumes/APPLE2T/Fotos}"

# 2. Destination Folder: Where the final .zip files will be saved
DEST_DIR="${2:-/Volumes/APPLE2T/BACKUP/Fotos}"

# 3. Archive Name Prefix: [PREFIX] - [FOLDER] - yyyy-MM-dd-HH-mm-ss.zip
BACKUP_NAME_PREFIX="${3:-Fotos}"

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

# List immediate subfolders in reverse name order (newest year first).
SOURCE_DIR="${SOURCE_DIR:a}"
PHOTO_FOLDERS=( "${SOURCE_DIR%/}"/*(N/On) )
FOLDER_COUNT=${#PHOTO_FOLDERS}
if (( FOLDER_COUNT == 0 )); then
    echo "❌ Error: No photo subfolders found in $SOURCE_DIR"
    exit 1
fi

echo ""
echo "Photo folders available for backup:"
for (( i = 1; i <= FOLDER_COUNT; i++ )); do
    printf '  %d) %s\n' "$i" "${PHOTO_FOLDERS[i]:t}"
done

SOURCE_PARENT="$(dirname "$SOURCE_DIR")"
SOURCE_BASENAME="$(basename "$SOURCE_DIR")"
typeset -aU ARCHIVE_FOLDERS

while true; do
    printf 'Enter folder numbers (spaces or commas; Enter to cancel): '
    if ! read -r selection || [[ "$selection" != *[^[:space:]]* ]]; then
        echo "Backup canceled. No archive created."
        exit 0
    fi

    read -rA choices <<< "${selection//,/ }"
    ARCHIVE_FOLDERS=()
    valid_selection=true
    for choice in "${choices[@]}"; do
        if [[ "$choice" != <-> || "$choice" == 0* || ${#choice} -gt ${#FOLDER_COUNT} ]] ||
           (( choice > FOLDER_COUNT )); then
            valid_selection=false
            break
        fi
        ARCHIVE_FOLDERS+=( "./${SOURCE_BASENAME}/${PHOTO_FOLDERS[choice]:t}" )
    done
    if [[ "$valid_selection" == true ]] && (( ${#ARCHIVE_FOLDERS} > 0 )); then
        break
    fi
    printf 'Invalid selection. Choose one or more folder numbers from 1 to %d.\n' "$FOLDER_COUNT"
done

# Step 3: Ensure target destination directory exists (creates subfolders if missing)
if [ ! -d "$DEST_DIR" ]; then
    echo "📁 Creating missing destination folder: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# Step 4: Prepare one archive per selected folder and check for existing files
TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
typeset -a DEST_FILES
for ARCHIVE_FOLDER in "${ARCHIVE_FOLDERS[@]}"; do
    ARCHIVE_NAME="${BACKUP_NAME_PREFIX} - ${ARCHIVE_FOLDER:t} - ${TIMESTAMP}.zip"
    DEST_FILE="${DEST_DIR:a}/${ARCHIVE_NAME}"
    if [[ -e "$DEST_FILE" || -L "$DEST_FILE" ]]; then
        echo "❌ Error: An archive already exists: $DEST_FILE"
        echo "   Please try again."
        exit 1
    fi
    DEST_FILES+=( "$DEST_FILE" )
done

# ==============================================================================
# COMPRESSION PROCESS
# ==============================================================================

echo "\n📦 Archiving in progress... Please wait."

for (( i = 1; i <= ${#ARCHIVE_FOLDERS}; i++ )); do
    ARCHIVE_FOLDER="${ARCHIVE_FOLDERS[i]}"
    DEST_FILE="${DEST_FILES[i]}"
    ARCHIVE_NAME="${DEST_FILE:t}"

    # Execute zip from parent directory so the root path is not embedded in the archive
    (
        cd "$SOURCE_PARENT"
        # Options:
        #   -r : Recurse into directories
        #   -q : Quiet operation (suppresses thousands of file lines for speed)
        #   -x : Exclude invisible macOS filesystem metadata files (.DS_Store)
        #   -MM : Fail if an input is missing or unreadable
        zip -r -q -MM "$DEST_FILE" "$ARCHIVE_FOLDER" -x "*.DS_Store"
    )

    if [ ! -f "$DEST_FILE" ]; then
        echo "\n❌ Error: Backup file could not be verified at destination: $DEST_FILE"
        exit 1
    fi
    FILE_SIZE=$(du -sh "$DEST_FILE" | awk '{print $1}')
    
    echo "\n Archive created successfully! 📦"
    echo "----------------------------------------------------------------------------------------------------"
    echo "File Name:    $ARCHIVE_NAME"
    echo "File Size:    $FILE_SIZE"
    echo "Saved at:     $DEST_FILE"
    echo "----------------------------------------------------------------------------------------------------"
done

# ==============================================================================
# COMPLETION
# ==============================================================================

echo "\n Backup completed successfully! ${#DEST_FILES} archive(s) created."

# Trigger native macOS Desktop Notification with sound
osascript <<EOF
display notification "${#DEST_FILES} photo archive(s) created." \
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