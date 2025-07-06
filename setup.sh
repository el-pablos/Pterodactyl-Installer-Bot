#!/bin/bash

# Setup Script for Pterodactyl Panel Installer Bot v2.1
# Automatic setup for Linux/Unix systems

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BOT_USER="pterodactyl-bot"
BOT_DIR="/opt/pterodactyl-bot"
SERVICE_NAME="pterodactyl-bot"
LOG_DIR="/var/log/pterodactyl-bot"

print_header() {
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE} Pterodactyl Bot Setup Script v2.1${NC}"
    echo -e "${PURPLE} Automatic Installation & Configuration${NC}"
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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        print_info "Use: sudo $0"
        exit 1
    fi
}

# Detect OS
detect_os() {
    print_step "Detecting operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    print_info "Detected: $OS $VER"
    
    # Check if supported
    case $ID in
        ubuntu)
            if [[ "$VER" != "20.04" && "$VER" != "22.04" ]]; then
                print_warning "Ubuntu $VER may not be fully supported"
                print_info "Recommended: Ubuntu 20.04 or 22.04 LTS"
            fi
            PACKAGE_MANAGER="apt"
            ;;
        debian)
            PACKAGE_MANAGER="apt"
            ;;
        centos|rhel|fedora)
            PACKAGE_MANAGER="yum"
            ;;
        *)
            print_warning "Unsupported OS: $ID"
            print_info "This script is optimized for Ubuntu/Debian"
            PACKAGE_MANAGER="unknown"
            ;;
    esac
}

# Install dependencies
install_dependencies() {
    print_step "Installing system dependencies..."
    
    case $PACKAGE_MANAGER in
        apt)
            apt update
            apt install -y curl wget git software-properties-common
            
            # Install Node.js
            if ! command -v node &> /dev/null; then
                print_info "Installing Node.js..."
                curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
                apt install -y nodejs
            fi
            ;;
        yum)
            yum update -y
            yum install -y curl wget git
            
            # Install Node.js
            if ! command -v node &> /dev/null; then
                print_info "Installing Node.js..."
                curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
                yum install -y nodejs
            fi
            ;;
        *)
            print_error "Unknown package manager. Please install Node.js manually"
            exit 1
            ;;
    esac
    
    # Verify installations
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        print_success "Node.js $(node --version) and npm $(npm --version) installed"
    else
        print_error "Failed to install Node.js/npm"
        exit 1
    fi
}

# Create bot user
create_bot_user() {
    print_step "Creating bot user..."
    
    if id "$BOT_USER" &>/dev/null; then
        print_info "User $BOT_USER already exists"
    else
        useradd -r -d "$BOT_DIR" -s /bin/bash "$BOT_USER"
        print_success "Created user: $BOT_USER"
    fi
}

# Setup bot directory
setup_bot_directory() {
    print_step "Setting up bot directory..."
    
    # Create directory
    mkdir -p "$BOT_DIR"
    mkdir -p "$LOG_DIR"
    
    # Copy bot files
    if [ -f "./bot.js" ]; then
        print_info "Copying bot files..."
        cp -r ./* "$BOT_DIR/"
        
        # Remove sensitive files if exist
        rm -f "$BOT_DIR/.env"
        
        # Set permissions
        chown -R "$BOT_USER:$BOT_USER" "$BOT_DIR"
        chown -R "$BOT_USER:$BOT_USER" "$LOG_DIR"
        chmod +x "$BOT_DIR"/*.sh
        
        print_success "Bot files copied to $BOT_DIR"
    else
        print_error "Bot files not found in current directory"
        exit 1
    fi
}

# Install node dependencies
install_node_dependencies() {
    print_step "Installing Node.js dependencies..."
    
    cd "$BOT_DIR"
    
    # Install as bot user
    sudo -u "$BOT_USER" npm install
    
    if [ $? -eq 0 ]; then
        print_success "Node.js dependencies installed"
    else
        print_error "Failed to install Node.js dependencies"
        exit 1
    fi
}

# Configure environment
configure_environment() {
    print_step "Configuring environment..."
    
    # Create .env file if not exists
    if [ ! -f "$BOT_DIR/.env" ]; then
        print_info "Creating environment file..."
        cp "$BOT_DIR/.env.example" "$BOT_DIR/.env"
        
        # Set proper permissions
        chown "$BOT_USER:$BOT_USER" "$BOT_DIR/.env"
        chmod 600 "$BOT_DIR/.env"
        
        print_warning "Please edit $BOT_DIR/.env with your configuration"
        print_info "Required: BOT_TOKEN, OWNER_ID"
    fi
}

# Create systemd service
create_systemd_service() {
    print_step "Creating systemd service..."
    
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=Pterodactyl Panel Installer Bot
After=network.target
Wants=network.target

[Service]
Type=simple
User=$BOT_USER
Group=$BOT_USER
WorkingDirectory=$BOT_DIR
ExecStart=/usr/bin/node bot.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production
Environment=PATH=/usr/bin:/usr/local/bin
StandardOutput=append:$LOG_DIR/bot.log
StandardError=append:$LOG_DIR/error.log

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$BOT_DIR $LOG_DIR
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    print_success "Systemd service created: $SERVICE_NAME"
    print_info "Service file: /etc/systemd/system/${SERVICE_NAME}.service"
}

# Setup log rotation
setup_log_rotation() {
    print_step "Setting up log rotation..."
    
    cat > "/etc/logrotate.d/$SERVICE_NAME" << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
    su $BOT_USER $BOT_USER
}
EOF
    
    print_success "Log rotation configured"
}

# Setup firewall (if UFW is available)
setup_firewall() {
    if command -v ufw &> /dev/null; then
        print_step "Configuring firewall..."
        
        # Allow SSH (just in case)
        ufw allow ssh
        
        print_info "Firewall configuration completed"
        print_warning "Make sure SSH (port 22) is allowed before enabling UFW"
    fi
}

# Create management scripts
create_management_scripts() {
    print_step "Creating management scripts..."
    
    # Create bot control script
    cat > "/usr/local/bin/pterodactyl-bot" << 'EOF'
#!/bin/bash

SERVICE_NAME="pterodactyl-bot"
BOT_DIR="/opt/pterodactyl-bot"
LOG_DIR="/var/log/pterodactyl-bot"

case "$1" in
    start)
        echo "Starting Pterodactyl Bot..."
        systemctl start $SERVICE_NAME
        ;;
    stop)
        echo "Stopping Pterodactyl Bot..."
        systemctl stop $SERVICE_NAME
        ;;
    restart)
        echo "Restarting Pterodactyl Bot..."
        systemctl restart $SERVICE_NAME
        ;;
    status)
        systemctl status $SERVICE_NAME
        ;;
    logs)
        tail -f $LOG_DIR/bot.log
        ;;
    errors)
        tail -f $LOG_DIR/error.log
        ;;
    update)
        echo "Updating bot dependencies..."
        cd $BOT_DIR
        sudo -u pterodactyl-bot npm update
        systemctl restart $SERVICE_NAME
        echo "Bot updated and restarted"
        ;;
    config)
        echo "Opening configuration file..."
        nano $BOT_DIR/.env
        echo "Configuration updated. Restart bot to apply changes."
        ;;
    backup)
        echo "Creating configuration backup..."
        cd $BOT_DIR
        sudo -u pterodactyl-bot ./backup-restore.sh backup
        ;;
    test)
        echo "Running bot tests..."
        cd $BOT_DIR
        sudo -u pterodactyl-bot ./test-bot.sh
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|errors|update|config|backup|test}"
        echo
        echo "Commands:"
        echo "  start   - Start the bot service"
        echo "  stop    - Stop the bot service"
        echo "  restart - Restart the bot service"
        echo "  status  - Show service status"
        echo "  logs    - Show bot logs (real-time)"
        echo "  errors  - Show error logs (real-time)"
        echo "  update  - Update bot dependencies"
        echo "  config  - Edit configuration"
        echo "  backup  - Create configuration backup"
        echo "  test    - Run bot tests"
        exit 1
        ;;
esac
EOF
    
    chmod +x "/usr/local/bin/pterodactyl-bot"
    
    print_success "Management script created: /usr/local/bin/pterodactyl-bot"
    print_info "Usage: pterodactyl-bot {start|stop|restart|status|logs|errors|update|config|backup|test}"
}

# Setup monitoring
setup_monitoring() {
    print_step "Setting up monitoring..."
    
    # Create monitoring script
    cat > "$BOT_DIR/monitor-health.sh" << EOF
#!/bin/bash

# Health check script for Pterodactyl Bot
SERVICE_NAME="pterodactyl-bot"
LOG_FILE="/var/log/pterodactyl-bot/health.log"

# Check if service is running
if systemctl is-active --quiet \$SERVICE_NAME; then
    echo "\$(date): Service is running" >> \$LOG_FILE
else
    echo "\$(date): Service is down, attempting restart" >> \$LOG_FILE
    systemctl restart \$SERVICE_NAME
    
    # Wait a moment and check again
    sleep 5
    if systemctl is-active --quiet \$SERVICE_NAME; then
        echo "\$(date): Service restarted successfully" >> \$LOG_FILE
    else
        echo "\$(date): Failed to restart service" >> \$LOG_FILE
    fi
fi
EOF
    
    chmod +x "$BOT_DIR/monitor-health.sh"
    chown "$BOT_USER:$BOT_USER" "$BOT_DIR/monitor-health.sh"
    
    # Add to crontab for bot user
    (crontab -u "$BOT_USER" -l 2>/dev/null; echo "*/5 * * * * $BOT_DIR/monitor-health.sh") | crontab -u "$BOT_USER" -
    
    print_success "Health monitoring setup completed"
    print_info "Health checks run every 5 minutes"
}

# Final configuration
final_configuration() {
    print_step "Final configuration..."
    
    # Test bot syntax
    cd "$BOT_DIR"
    if sudo -u "$BOT_USER" node -c bot.js; then
        print_success "Bot syntax is valid"
    else
        print_error "Bot syntax error detected"
        print_warning "Please check the bot configuration"
    fi
    
    # Display next steps
    echo
    print_success "Setup completed successfully!"
    echo
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Edit configuration: pterodactyl-bot config"
    echo "2. Start the bot: pterodactyl-bot start"
    echo "3. Check status: pterodactyl-bot status"
    echo "4. View logs: pterodactyl-bot logs"
    echo "5. Test bot: pterodactyl-bot test"
    echo
    echo -e "${CYAN}Configuration File:${NC} $BOT_DIR/.env"
    echo -e "${CYAN}Management Command:${NC} pterodactyl-bot"
    echo -e "${CYAN}Service Name:${NC} $SERVICE_NAME"
    echo -e "${CYAN}Log Directory:${NC} $LOG_DIR"
    echo
    print_warning "Don't forget to configure BOT_TOKEN and OWNER_ID in .env file!"
}

# Uninstall function
uninstall() {
    print_step "Uninstalling Pterodactyl Bot..."
    
    # Stop and disable service
    systemctl stop "$SERVICE_NAME" 2>/dev/null
    systemctl disable "$SERVICE_NAME" 2>/dev/null
    
    # Remove service file
    rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    systemctl daemon-reload
    
    # Remove management script
    rm -f "/usr/local/bin/pterodactyl-bot"
    
    # Remove log rotation
    rm -f "/etc/logrotate.d/$SERVICE_NAME"
    
    # Remove bot directory and logs
    rm -rf "$BOT_DIR"
    rm -rf "$LOG_DIR"
    
    # Remove bot user
    userdel -r "$BOT_USER" 2>/dev/null
    
    print_success "Pterodactyl Bot uninstalled successfully"
}

# Show help
show_help() {
    print_header
    echo
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  install    - Install and setup the bot (default)"
    echo "  uninstall  - Remove the bot completely"
    echo "  help       - Show this help message"
    echo
    echo "Installation includes:"
    echo "  - System dependencies (Node.js, npm)"
    echo "  - Bot user and directory setup"
    echo "  - Systemd service configuration"
    echo "  - Log rotation setup"
    echo "  - Management scripts"
    echo "  - Health monitoring"
    echo
}

# Main installation process
install_bot() {
    print_header
    echo
    
    print_info "Starting Pterodactyl Bot installation..."
    echo
    
    check_root
    detect_os
    install_dependencies
    create_bot_user
    setup_bot_directory
    install_node_dependencies
    configure_environment
    create_systemd_service
    setup_log_rotation
    setup_firewall
    create_management_scripts
    setup_monitoring
    final_configuration
}

# Main function
main() {
    case "${1:-install}" in
        "install")
            install_bot
            ;;
        "uninstall")
            print_header
            echo
            echo -n "Are you sure you want to uninstall Pterodactyl Bot? [y/N]: "
            read -r confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                uninstall
            else
                print_info "Uninstall cancelled"
            fi
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
