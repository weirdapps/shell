#!/bin/zsh

# Configuration
BACKUP_DIR="/Volumes/BackupDrive"
BACKUP_DIRS=("Documents" "Pictures" "Desktop")
LOG_FILE="$HOME/Library/Logs/maintenance-$(date +%Y%m%d-%H%M%S).log"
DOWNLOADS_RETENTION_DAYS=30
IOS_BACKUP_RETENTION_DAYS=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print messages with timestamp and color
print_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=============================="
    echo -e "${GREEN}[$timestamp] $1${NC}"
    echo "=============================="
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Function to print errors
print_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[$timestamp] ERROR: $1${NC}" >&2
    echo "[$timestamp] ERROR: $1" >> "$LOG_FILE"
}

# Function to print warnings
print_warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[$timestamp] WARNING: $1${NC}"
    echo "[$timestamp] WARNING: $1" >> "$LOG_FILE"
}

# Function to safely remove files
safe_remove() {
    local path="$1"
    local pattern="$2"
    local days="$3"
    
    if [[ -d "$path" ]]; then
        find "$path" -mindepth 1 $pattern -mtime +$days -print -delete 2>/dev/null | while read file; do
            echo "Removing: $file" >> "$LOG_FILE"
        done
    else
        print_warning "Directory not found: $path"
    fi
}

# Parse command line options
SKIP_SYSTEM_UPDATE=false
SKIP_HOMEBREW=false
SKIP_CLEANUP=false
SKIP_APPSTORE=false
SKIP_BACKUP=false

while getopts "hsHCAB" opt; do
    case $opt in
        h)
            echo "Usage: $0 [-s] [-H] [-C] [-A] [-B]"
            echo "  -s: Skip system update"
            echo "  -H: Skip Homebrew update"
            echo "  -C: Skip cleanup operations"
            echo "  -A: Skip App Store updates"
            echo "  -B: Skip backup operations"
            exit 0
            ;;
        s) SKIP_SYSTEM_UPDATE=true ;;
        H) SKIP_HOMEBREW=true ;;
        C) SKIP_CLEANUP=true ;;
        A) SKIP_APPSTORE=true ;;
        B) SKIP_BACKUP=true ;;
        \?)
            print_error "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done

# Initialize log file
mkdir -p "$(dirname "$LOG_FILE")"
echo "Maintenance script started at $(date)" > "$LOG_FILE"

# Function to run user-level operations (no sudo required)
run_user_operations() {
    # Homebrew Update and Cleanup
    if ! $SKIP_HOMEBREW; then
        print_message "Updating and Cleaning Homebrew"
        if command -v brew >/dev/null 2>&1; then
            if brew update >> "$LOG_FILE" 2>&1; then
                brew upgrade >> "$LOG_FILE" 2>&1 && \
                brew cleanup >> "$LOG_FILE" 2>&1 && \
                brew doctor >> "$LOG_FILE" 2>&1 || \
                print_warning "Some Homebrew operations completed with warnings"
            else
                print_error "Homebrew operations failed"
            fi
        else
            print_warning "Homebrew not found. Skipping Homebrew updates."
        fi
    fi

    # Update App Store applications
    if ! $SKIP_APPSTORE; then
        print_message "Updating App Store Applications"
        if command -v mas >/dev/null 2>&1; then
            if mas upgrade >> "$LOG_FILE" 2>&1; then
                print_message "App Store updates completed successfully"
            else
                print_warning "Some App Store updates may have failed"
            fi
        else
            print_warning "mas CLI not found. Skipping App Store updates."
        fi
    fi
}

# Function to run sudo operations
run_sudo_operations() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Sudo operations must be run with sudo privileges"
        exit 1
    fi

    # System Update
    if ! $SKIP_SYSTEM_UPDATE; then
        print_message "Starting System Update"
        if ! softwareupdate -ia --verbose >> "$LOG_FILE" 2>&1; then
            print_error "System update failed"
        fi
    fi

    # Clean Caches
    if ! $SKIP_CLEANUP; then
        print_message "Cleaning System Caches"
        for cache_dir in "/Library/Caches" "/System/Library/Caches"; do
            if [[ -d "$cache_dir" ]]; then
                sudo find "$cache_dir" -mindepth 1 -maxdepth 1 -type d ! -name "com.apple.*" -print -delete 2>/dev/null | \
                    while read file; do
                        echo "Removing cache: $file" >> "$LOG_FILE"
                    done
            fi
        done

        # Clean temporary files using tmutil
        print_message "Cleaning Temporary Files"
        if tmutil listlocalsnapshots / | grep -q "com.apple.TimeMachine"; then
            sudo tmutil deletelocalsnapshots / >> "$LOG_FILE" 2>&1
        else
            print_warning "No local Time Machine snapshots found"
        fi

        # Remove old files from Downloads
        print_message "Cleaning Downloads Folder"
        safe_remove "$HOME/Downloads" "" $DOWNLOADS_RETENTION_DAYS

        # Purge inactive memory
        print_message "Purging Inactive Memory"
        sudo purge >> "$LOG_FILE" 2>&1

        # Remove old iOS device backups
        print_message "Removing old iOS device backups"
        safe_remove "$HOME/Library/Application Support/MobileSync/Backup" "" $IOS_BACKUP_RETENTION_DAYS

        # Clear application logs
        print_message "Clearing Application Logs"
        log_directories=(
            /private/var/log
            /private/var/log/asl
            /private/var/log/powermanagement
        )

        for dir in $log_directories; do
            if [[ -d "$dir" ]]; then
                sudo find "$dir" -mindepth 1 -type f -print -delete 2>/dev/null | \
                    while read file; do
                        echo "Removing log: $file" >> "$LOG_FILE"
                    done
            fi
        done
    fi

    # Verify system preferences
    print_message "Verifying System Preferences"
    if ! defaults read > /dev/null 2>&1; then
        print_warning "Some system preferences may need attention"
    fi
}

# Main execution
if [[ $EUID -eq 0 ]]; then
    # If running as root, execute sudo operations
    run_sudo_operations
    
    # Get the real user who invoked sudo
    REAL_USER=$(who am i | awk '{print $1}')
    if [[ -n "$REAL_USER" ]]; then
        # Run user operations as the real user
        print_message "Running user-level operations..."
        sudo -u "$REAL_USER" zsh -c "$(declare -f print_message print_error print_warning run_user_operations); SKIP_HOMEBREW=$SKIP_HOMEBREW SKIP_APPSTORE=$SKIP_APPSTORE LOG_FILE='$LOG_FILE' run_user_operations"
    else
        print_error "Could not determine real user for user-level operations"
    fi
else
    # If not running as root, execute user operations first
    run_user_operations
    
    # Then use sudo for system operations
    print_message "Requesting sudo privileges for system operations..."
    sudo zsh -c "$(declare -f print_message print_error print_warning safe_remove run_sudo_operations); SKIP_SYSTEM_UPDATE=$SKIP_SYSTEM_UPDATE SKIP_CLEANUP=$SKIP_CLEANUP LOG_FILE='$LOG_FILE' run_sudo_operations"
fi

print_message "Maintenance Script Completed"
echo "Log file available at: $LOG_FILE"