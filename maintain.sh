#!/bin/zsh

# Function to print messages
print_message() {
    echo "=============================="
    echo $1
    echo "=============================="
}

# System Update
print_message "Starting System Update"
softwareupdate -ia --verbose

# Homebrew Update and Cleanup
print_message "Updating and Cleaning Homebrew"
if command -v brew >/dev/null 2>&1; then
    brew update
    brew upgrade
    brew cleanup
    brew doctor
else
    echo "Homebrew not found. Skipping Homebrew updates."
fi

# Clean Caches
print_message "Cleaning System Caches"
if [[ -d "/Library/Caches" ]]; then
    sudo find /Library/Caches -mindepth 1 -maxdepth 1 -type d ! -name "com.apple.*" -exec rm -rf {} \; 2>/dev/null
fi
if [[ -d "/System/Library/Caches" ]]; then
    sudo find /System/Library/Caches -mindepth 1 -maxdepth 1 -type d ! -name "com.apple.*" -exec rm -rf {} \; 2>/dev/null
fi

# Clean temporary files using tmutil
print_message "Cleaning Temporary Files"
sudo tmutil deletelocalsnapshots /

# Remove unused files from Downloads
print_message "Cleaning Downloads Folder"
if [[ -d ~/Downloads ]]; then
    find ~/Downloads -mindepth 1 -exec rm -rf {} \;
fi

# Purge inactive memory
print_message "Purging Inactive Memory"
sudo purge

# Update App Store applications
print_message "Updating App Store Applications"
if command -v mas >/dev/null 2>&1; then
    mas upgrade
else
    echo "mas CLI not found. Skipping App Store updates."
fi

# Remove old iOS device backups
print_message "Removing old iOS device backups"
if [[ -d ~/Library/Application\ Support/MobileSync/Backup ]]; then
    find ~/Library/Application\ Support/MobileSync/Backup -mindepth 1 -exec rm -rf {} \;
fi

# Clear application logs
print_message "Clearing Application Logs"
log_directories=(
    /private/var/log
    /private/var/log/asl
    # /private/var/log/DiagnosticMessages
    /private/var/log/powermanagement
    /private/var/log/install.log
)

for dir in $log_directories; do
    if [[ -d $dir ]]; then
        sudo find $dir -mindepth 1 -exec rm -rf {} \;
    fi
done

# Check for Malware
# print_message "Running Malware Check"
# if command -v malwarebytes >/dev/null 2>&1; then
#     sudo malwarebytes --scan --deep
# else
#     echo "Malwarebytes not found. Skipping malware scan."
# fi

# Verify system preferences
print_message "Verifying System Preferences"
defaults read > /dev/null 2>&1

# Backup important data
# print_message "Backing Up Important Data"
# rsync -av --delete ~/Documents/ /Volumes/BackupDrive/Documents/
# rsync -av --delete ~/Pictures/ /Volumes/BackupDrive/Pictures/
# rsync -av --delete ~/Desktop/ /Volumes/BackupDrive/Desktop/

print_message "Maintenance Script Completed"