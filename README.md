# macOS System Maintenance Script

A comprehensive shell script for automating common maintenance tasks on macOS systems. This script helps keep your system clean, updated, and running efficiently.

## Features

- System software updates
- Homebrew package updates and cleanup
- App Store application updates
- System cache cleanup
- Removal of old downloads
- iOS device backup management
- Log file cleanup
- Memory management
- Time Machine local snapshot cleanup

## Requirements

- macOS operating system
- Homebrew (optional, for package management)
- mas-cli (optional, for App Store updates)
- Administrative (sudo) privileges

## Installation

1. Clone or download the script to your preferred location
2. Make the script executable:
   ```bash
   chmod +x maintain.sh
   ```

## Usage

Run the script with:
```bash
./maintain.sh
```

For system-level operations, the script will automatically request sudo privileges when needed.

### Command Line Options

- `-h`: Display help message
- `-s`: Skip system update
- `-H`: Skip Homebrew update
- `-C`: Skip cleanup operations
- `-A`: Skip App Store updates
- `-B`: Skip backup operations

Example:
```bash
./maintain.sh -H -A  # Skip Homebrew and App Store updates
```

## Configuration

The script uses several configurable variables at the top:

```bash
BACKUP_DIR="/Volumes/BackupDrive"
BACKUP_DIRS=("Documents" "Pictures" "Desktop")
LOG_FILE="$HOME/Library/Logs/maintenance-[timestamp].log"
DOWNLOADS_RETENTION_DAYS=30
IOS_BACKUP_RETENTION_DAYS=30
```

Adjust these values according to your needs:
- `BACKUP_DIR`: Location of your backup drive
- `BACKUP_DIRS`: Directories to backup
- `DOWNLOADS_RETENTION_DAYS`: Number of days to keep files in Downloads folder
- `IOS_BACKUP_RETENTION_DAYS`: Number of days to keep iOS device backups

## Operations Performed

1. **System Updates**
   - Runs macOS software updates

2. **Package Management**
   - Updates Homebrew packages
   - Runs brew cleanup and doctor
   - Updates App Store applications

3. **System Cleanup**
   - Cleans system and library caches
   - Removes old files from Downloads folder
   - Deletes old iOS device backups
   - Purges inactive memory
   - Cleans system logs
   - Removes local Time Machine snapshots

## Logging

The script maintains detailed logs of all operations. Log files are stored at:
```
$HOME/Library/Logs/maintenance-[timestamp].log
```

Each log file includes timestamps and colored output for different types of messages (normal, warnings, errors).

## Safety Features

- Safe file removal with age checking
- Error handling and reporting
- Separate user-level and system-level operations
- Verification of system preferences
- Colored output for different message types (normal, warnings, errors)