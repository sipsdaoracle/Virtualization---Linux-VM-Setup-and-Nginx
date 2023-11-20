#!/bin/bash

# Variables
BACKUP_DIR="/home/$(whoami)/nginx_backups"
CRON_JOB="0 0 * * * cp -r /etc/nginx $BACKUP_DIR/nginx_backup_$(date +\%Y\%m\%d)"

# Error handling function
handle_error() {
    echo "Error: $1"
    exit 1
}

# Create backup directory if it doesn't exist
create_backup_directory() {
    if [ ! -d "$BACKUP_DIR" ]
    then
        mkdir -p "$BACKUP_DIR" || handle_error "Failed to create backup directory."
        echo "Backup directory created: $BACKUP_DIR"
    else
        echo "Backup directory already exists: $BACKUP_DIR"
    fi
}

# Setup cron job for Nginx backup
setup_cron_job() {
    if ! (crontab -l 2>/dev/null | { cat; echo "$CRON_JOB"; } | crontab -)
    then
        handle_error "Failed to setup cron job."
    else
        echo "Cron job successfully set up."
    fi
}

# Display success messages
display_success() {
    echo "--------------------------------------"
    echo "Task completed successfully!"
    echo "--------------------------------------"
    echo "Backup directory: $BACKUP_DIR"
    echo "Cron job: $CRON_JOB"
    echo "--------------------------------------"
}
# Main script
create_backup_directory
setup_cron_job
display_success