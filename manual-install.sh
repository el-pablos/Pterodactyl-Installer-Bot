#!/bin/bash

# Manual Pterodactyl Panel Installation Script
# Use this if the bot installation fails

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration - EDIT THESE VALUES
DOMAIN_PANEL="panel.tams.my.id"
DOMAIN_NODE="node.tams.my.id"
EMAIL="ndikafath@ndikafath.store"
USERNAME="admin"
PASSWORD="admin123"
RAM_SERVER="8000"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check OS
check_os() {
    print_status "Checking OS compatibility..."
    
    OS_VERSION=$(lsb_release -rs 2>/dev/null)
    case $OS_VERSION in
        "20.04"|"22.04")
            print_success "Ubuntu $OS_VERSION is supported!"
            ;;
        *)
            print_error "Ubuntu $OS_VERSION is NOT supported!"
            print_error "Please use Ubuntu 20.04 or 22.04 LTS"
            exit 1
            ;;
    esac
}

# Update system
update_system() {
    print_status "Updating system packages..."
    apt update && apt upgrade -y
    print_success "System updated!"
}

# Install Panel
install_panel() {
    print_status "Installing Pterodactyl Panel..."
    
    # Download installer
    curl -Lo panel-installer.sh https://pterodactyl-installer.se
    chmod +x panel-installer.sh
    
    # Create expect script for automated input
    cat > panel_install.exp << EOF
#!/usr/bin/expect -f
set timeout 600

spawn ./panel-installer.sh

expect "Input 0-6:" { send "0\r" }
expect "(y/N)" { send "y\r" }
expect "Database name (panel):" { send "\r" }
expect "Database username (pterodactyl):" { send "$USERNAME\r" }
expect "Password (press enter to use randomly generated password):" { send "$PASSWORD\r" }
expect "Select timezone*:" { send "Asia/Jakarta\r" }
expect "Provide the email address*:" { send "$EMAIL\r" }
expect "Email address for the initial admin account:" { send "$EMAIL\r" }
expect "Username for the initial admin account:" { send "$USERNAME\r" }
expect "First name for the initial admin account:" { send "$USERNAME\r" }
expect "Last name for the initial admin account:" { send "$USERNAME\r" }
expect "Password for the initial admin account:" { send "$PASSWORD\r" }
expect "Set the FQDN of this panel*:" { send "$DOMAIN_PANEL\r" }
expect "Do you want to automatically configure UFW*:" { send "y\r" }
expect "Do you want to automatically configure HTTPS*:" { send "y\r" }
expect "Select the appropriate number*:" { send "1\r" }
expect "I agree that this HTTPS request is performed*:" { send "y\r" }
expect "Proceed anyways*:" { send "y\r" }
expect "(yes/no)" { send "y\r" }
expect "Initial configuration completed*:" { send "y\r" }
expect "Still assume SSL*:" { send "y\r" }
expect "Please read the Terms of Service" { send "y\r" }
expect "(A)gree/(C)ancel:" { send "A\r" }

expect eof
EOF

    chmod +x panel_install.exp
    ./panel_install.exp
    
    if [ -d "/var/www/pterodactyl" ]; then
        print_success "Panel installed successfully!"
    else
        print_error "Panel installation failed!"
        exit 1
    fi
}

# Install Wings
install_wings() {
    print_status "Installing Wings..."
    
    # Create expect script for wings
    cat > wings_install.exp << EOF
#!/usr/bin/expect -f
set timeout 600

spawn ./panel-installer.sh

expect "Input 0-6:" { send "1\r" }
expect "(y/N)" { send "y\r" }
expect "Enter the panel address*:" { send "$DOMAIN_PANEL\r" }
expect "Database host username*:" { send "$USERNAME\r" }
expect "Database host password:" { send "$PASSWORD\r" }
expect "Set the FQDN to use for Let's Encrypt*:" { send "$DOMAIN_NODE\r" }
expect "Enter email address for Let's Encrypt:" { send "$EMAIL\r" }

expect eof
EOF

    chmod +x wings_install.exp
    ./wings_install.exp
    
    print_success "Wings installation completed!"
}

# Create Node
create_node() {
    print_status "Creating node..."
    
    curl -Lo createnode.sh https://raw.githubusercontent.com/jarroffc/jarroffc/main/createnode.sh
    chmod +x createnode.sh
    
    cat > node_create.exp << EOF
#!/usr/bin/expect -f
set timeout 300

spawn ./createnode.sh

expect "Masukkan nama lokasi:" { send "Singapore\r" }
expect "Masukkan deskripsi lokasi:" { send "Node By NdikaFath ID\r" }
expect "Masukkan domain:" { send "$DOMAIN_NODE\r" }
expect "Masukkan nama node:" { send "NdikaFath ID\r" }
expect "Masukkan RAM (dalam MB):" { send "$RAM_SERVER\r" }
expect "Masukkan jumlah maksimum disk space (dalam MB):" { send "$RAM_SERVER\r" }
expect "Masukkan Locid:" { send "1\r" }

expect eof
EOF

    chmod +x node_create.exp
    ./node_create.exp
    
    print_success "Node created successfully!"
}

# Check installation
check_installation() {
    print_status "Checking installation..."
    
    # Check services
    services=("nginx" "mysql" "redis-server" "pterodactyl-queue-worker")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            print_success "$service is running"
        else
            print_error "$service is not running"
        fi
    done
    
    # Check directories
    if [ -d "/var/www/pterodactyl" ]; then
        print_success "Panel directory exists"
    else
        print_error "Panel directory not found"
    fi
    
    if [ -d "/etc/pterodactyl" ]; then
        print_success "Wings directory exists"
    else
        print_error "Wings directory not found"
    fi
    
    # Show credentials
    echo
    echo "🎉 Installation Summary:"
    echo "========================"
    echo "Panel URL: https://$DOMAIN_PANEL"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "Node Domain: $DOMAIN_NODE"
    echo
    echo "📝 Next Steps:"
    echo "1. Access panel and create allocation"
    echo "2. Get wings token from node settings"
    echo "3. Configure wings: systemctl start wings"
    echo
}

# Main function
main() {
    echo "🚀 Manual Pterodactyl Installation Script"
    echo "========================================"
    echo
    echo "📋 Configuration:"
    echo "Panel Domain: $DOMAIN_PANEL"
    echo "Node Domain: $DOMAIN_NODE"
    echo "Email: $EMAIL"
    echo "Username: $USERNAME"
    echo "RAM: ${RAM_SERVER}MB"
    echo
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
    
    # Install expect if not present
    if ! command -v expect &> /dev/null; then
        print_status "Installing expect..."
        apt update && apt install -y expect
    fi
    
    check_os
    update_system
    install_panel
    sleep 5
    install_wings
    sleep 3
    create_node
    check_installation
    
    print_success "Manual installation completed!"
}

# Run main function
main
