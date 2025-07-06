#!/bin/bash

# Backup and Restore Script for Pterodactyl Panel Installer Bot
# Version: 2.1.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
BACKUP_DIR="./backups"
CONFIG_FILES=("config.js" ".env" "package.json" "bot.js")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PREFIX="pterodactyl_bot_backup"

print_header() {
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE} Pterodactyl Bot Backup & Restore Tool${NC}"
    echo -e "${PURPLE} Version 2.1.0${NC}"
    echo -e "${PURPLE}============================================${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_info "Created backup directory: $BACKUP_DIR"
    fi
}

# Backup configuration
backup_config() {
    print_info "Starting configuration backup..."
    create_backup_dir
    
    local backup_file="${BACKUP_DIR}/${BACKUP_PREFIX}_${TIMESTAMP}.tar.gz"
    local temp_dir="/tmp/${BACKUP_PREFIX}_${TIMESTAMP}"
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    
    # Copy configuration files
    local files_backed_up=0
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "$temp_dir/"
            print_info "Backed up: $file"
            ((files_backed_up++))
        else
            print_warning "File not found: $file"
        fi
    done
    
    # Add system information
    cat > "$temp_dir/backup_info.txt" << EOF
Pterodactyl Bot Backup Information
==================================
Backup Date: $(date)
Bot Version: 2.1.0
Platform: $(uname -s) $(uname -m)
Node.js Version: $(node --version 2>/dev/null || echo "Not available")
npm Version: $(npm --version 2>/dev/null || echo "Not available")
Working Directory: $(pwd)
Files Backed Up: $files_backed_up
Backup Created By: $(whoami)

Files Included:
EOF
    
    # List backed up files
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$temp_dir/$file" ]; then
            echo "✓ $file" >> "$temp_dir/backup_info.txt"
        else
            echo "✗ $file (not found)" >> "$temp_dir/backup_info.txt"
        fi
    done
    
    # Create compressed backup
    tar -czf "$backup_file" -C "/tmp" "${BACKUP_PREFIX}_${TIMESTAMP}"
    
    # Cleanup temporary directory
    rm -rf "$temp_dir"
    
    if [ -f "$backup_file" ]; then
        local backup_size=$(du -h "$backup_file" | cut -f1)
        print_success "Backup created successfully!"
        print_info "Backup file: $backup_file"
        print_info "Backup size: $backup_size"
        print_info "Files backed up: $files_backed_up"
        return 0
    else
        print_error "Failed to create backup file"
        return 1
    fi
}

# List available backups
list_backups() {
    print_info "Available backups:"
    echo
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        print_warning "No backups found in $BACKUP_DIR"
        return 1
    fi
    
    local count=0
    for backup in "$BACKUP_DIR"/${BACKUP_PREFIX}_*.tar.gz; do
        if [ -f "$backup" ]; then
            ((count++))
            local filename=$(basename "$backup")
            local size=$(du -h "$backup" | cut -f1)
            local date=$(echo "$filename" | sed "s/${BACKUP_PREFIX}_\([0-9]\{8\}_[0-9]\{6\}\).*/\1/" | sed 's/_/ /')
            local formatted_date=$(date -d "${date:0:4}-${date:4:2}-${date:6:2} ${date:9:2}:${date:11:2}:${date:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$date")
            
            echo -e "${count}. ${BLUE}$filename${NC}"
            echo -e "   Date: $formatted_date"
            echo -e "   Size: $size"
            echo -e "   Path: $backup"
            echo
        fi
    done
    
    if [ $count -eq 0 ]; then
        print_warning "No valid backup files found"
        return 1
    fi
    
    print_info "Total backups: $count"
    return 0
}

# Restore configuration
restore_config() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify a backup file to restore"
        echo "Usage: $0 restore <backup_file>"
        echo "Use '$0 list' to see available backups"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_info "Restoring configuration from: $backup_file"
    
    # Create temporary directory for extraction
    local temp_dir="/tmp/restore_${TIMESTAMP}"
    mkdir -p "$temp_dir"
    
    # Extract backup
    if tar -xzf "$backup_file" -C "$temp_dir" 2>/dev/null; then
        print_info "Backup extracted successfully"
    else
        print_error "Failed to extract backup file"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find extracted directory
    local extracted_dir=$(find "$temp_dir" -type d -name "${BACKUP_PREFIX}_*" | head -1)
    if [ -z "$extracted_dir" ]; then
        print_error "Invalid backup format"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Display backup information if available
    if [ -f "$extracted_dir/backup_info.txt" ]; then
        echo
        print_info "Backup Information:"
        cat "$extracted_dir/backup_info.txt"
        echo
    fi
    
    # Confirm restoration
    echo -n "Do you want to proceed with restoration? [y/N]: "
    read -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Restoration cancelled"
        rm -rf "$temp_dir"
        return 0
    fi
    
    # Backup current configuration before restoration
    print_info "Creating backup of current configuration..."
    backup_config
    
    # Restore files
    local files_restored=0
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$extracted_dir/$file" ]; then
            cp "$extracted_dir/$file" "./"
            print_success "Restored: $file"
            ((files_restored++))
        else
            print_warning "File not found in backup: $file"
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_success "Restoration completed!"
    print_info "Files restored: $files_restored"
    print_warning "Please restart the bot to apply changes"
    
    return 0
}

# Clean old backups
cleanup_backups() {
    local keep_days=${1:-7}
    
    print_info "Cleaning up backups older than $keep_days days..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "Backup directory not found"
        return 1
    fi
    
    local deleted_count=0
    find "$BACKUP_DIR" -name "${BACKUP_PREFIX}_*.tar.gz" -type f -mtime +$keep_days -print0 | while IFS= read -r -d '' file; do
        rm -f "$file"
        print_info "Deleted old backup: $(basename "$file")"
        ((deleted_count++))
    done
    
    if [ $deleted_count -eq 0 ]; then
        print_info "No old backups to clean up"
    else
        print_success "Cleaned up $deleted_count old backup(s)"
    fi
}

# Validate backup
validate_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify a backup file to validate"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_info "Validating backup: $backup_file"
    
    # Check if it's a valid tar.gz file
    if tar -tzf "$backup_file" >/dev/null 2>&1; then
        print_success "Backup file is valid"
        
        # List contents
        print_info "Backup contents:"
        tar -tzf "$backup_file" | sed 's/^/  /'
        
        return 0
    else
        print_error "Backup file is corrupted or invalid"
        return 1
    fi
}

# Auto backup (for cron jobs)
auto_backup() {
    local max_backups=${1:-5}
    
    print_info "Starting automatic backup..."
    
    # Create backup
    if backup_config; then
        print_success "Automatic backup completed"
        
        # Keep only the latest N backups
        local backup_count=$(ls -1 "$BACKUP_DIR"/${BACKUP_PREFIX}_*.tar.gz 2>/dev/null | wc -l)
        
        if [ $backup_count -gt $max_backups ]; then
            local delete_count=$((backup_count - max_backups))
            print_info "Removing $delete_count old backup(s) to keep latest $max_backups"
            
            ls -1t "$BACKUP_DIR"/${BACKUP_PREFIX}_*.tar.gz | tail -n +$((max_backups + 1)) | xargs rm -f
        fi
        
        return 0
    else
        print_error "Automatic backup failed"
        return 1
    fi
}

# Export configuration
export_config() {
    local export_file="bot_config_export_${TIMESTAMP}.env"
    
    print_info "Exporting configuration to: $export_file"
    
    cat > "$export_file" << 'EOF'
# Pterodactyl Bot Configuration Export
# Generated automatically - review before use

# Bot Configuration
EOF
    
    if [ -f "config.js" ]; then
        echo "# From config.js:" >> "$export_file"
        node -e "
        try {
            const config = require('./config.js');
            console.log('BOT_TOKEN=' + (config.BOT_TOKEN || ''));
            console.log('OWNER_ID=' + (config.OWNER_ID || ''));
            console.log('DEFAULT_EMAIL=' + (config.DEFAULT_EMAIL || ''));
        } catch(e) {
            console.log('# Error reading config.js: ' + e.message);
        }
        " >> "$export_file" 2>/dev/null
    fi
    
    if [ -f ".env" ]; then
        echo "" >> "$export_file"
        echo "# From .env file:" >> "$export_file"
        cat ".env" >> "$export_file"
    fi
    
    print_success "Configuration exported to: $export_file"
    print_warning "Review the exported file before using it"
}

# Show help
show_help() {
    print_header
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  backup                 Create a backup of current configuration"
    echo "  restore <file>         Restore configuration from backup file"
    echo "  list                   List available backups"
    echo "  validate <file>        Validate a backup file"
    echo "  cleanup [days]         Clean up old backups (default: 7 days)"
    echo "  auto [max_backups]     Auto backup with rotation (default: 5)"
    echo "  export                 Export current config to .env format"
    echo "  help                   Show this help message"
    echo
    echo "Examples:"
    echo "  $0 backup"
    echo "  $0 restore ./backups/pterodactyl_bot_backup_20250706_120000.tar.gz"
    echo "  $0 list"
    echo "  $0 cleanup 30"
    echo "  $0 auto 10"
    echo
}

# Main function
main() {
    case "${1:-help}" in
        "backup")
            print_header
            echo
            backup_config
            ;;
        "restore")
            print_header
            echo
            restore_config "$2"
            ;;
        "list")
            print_header
            echo
            list_backups
            ;;
        "validate")
            print_header
            echo
            validate_backup "$2"
            ;;
        "cleanup")
            print_header
            echo
            cleanup_backups "$2"
            ;;
        "auto")
            auto_backup "$2"
            ;;
        "export")
            print_header
            echo
            export_config
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
