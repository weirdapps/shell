#!/bin/bash

# Enhanced macOS Maintenance Script

echo "Starting maintenance script..."
echo "Timestamp: $(date)"
echo "Please make sure you've backed up your data before running this script!"
read -p "Press enter to continue..."

# Function to check the success of operations
check_status() {
    if [ $? -eq 0 ]; then
        echo "Successfully completed: $1"
    else
        echo "Failed to complete: $1"
        exit 1
    fi
}

# Update macOS
echo "Checking for macOS updates..."
softwareupdate -l
check_status "Check macOS updates"

# Uncomment the following lines if you wish to install updates automatically
#echo "Installing macOS updates..."
#softwareupdate -ia
#check_status "Install macOS updates"

# Clean up cache files
echo "Cleaning up cache files..."
sudo rm -rf ~/Library/Caches/* /Library/Caches/* 2>/dev/null
echo "Completed cleanup with possible permissions issues ignored."


# Remove temporary files
echo "Removing temporary files..."
sudo rm -rf /private/var/tmp/*
check_status "Remove temporary files"

# Clean up logs
echo "Cleaning up logs..."
sudo rm -rf /private/var/log/*
check_status "Cleanup log files"

# Empty the trash
echo "Emptying the trash..."
sudo rm -rf ~/.Trash/*
check_status "Empty the trash"

# Update Homebrew
if command -v brew &> /dev/null; then
    echo "Updating Homebrew..."
    brew update
    brew upgrade
    brew cleanup
    check_status "Homebrew update"
fi

# Run maintenance scripts
echo "Running maintenance scripts..."
sudo periodic daily
check_status "Run daily maintenance"
sudo periodic weekly
check_status "Run weekly maintenance"
sudo periodic monthly
check_status "Run monthly maintenance"

# Reindex Spotlight
echo "Reindexing Spotlight..."
sudo mdutil -E /
check_status "Reindex Spotlight"

echo "Maintenance complete!"
echo "Timestamp: $(date)"
