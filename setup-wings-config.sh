#!/bin/bash

# 🚀 Wings Configuration Setup Script
# Automatically setup Wings with the provided configuration

echo "🚀 Wings Configuration Setup"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if Wings is installed
if [ ! -f "/usr/local/bin/wings" ]; then
    print_error "Wings is not installed!"
    print_status "Please run /setupwings command first or install Wings manually"
    exit 1
fi

print_success "Wings binary found"

# Create configuration directory
mkdir -p /etc/pterodactyl
mkdir -p /var/lib/pterodactyl/volumes

# Create Wings configuration
print_status "Creating Wings configuration..."

cat > /etc/pterodactyl/config.yml << 'EOF'
debug: false
uuid: 2b372615-d696-43ae-b2e2-24d756377252
token_id: bCkM3gV3BNFTiNeS
token: mxSpfA8eSVvNw4woCs3Zx4ABq6SQMorVzxRpl7qQozo7isHvpQp13ns1l4ndbQJz
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: 'http://vpsdos.tams.my.id'
EOF

# Set proper permissions
chown -R root:root /etc/pterodactyl
chmod -R 755 /etc/pterodactyl
chown -R root:root /var/lib/pterodactyl

print_success "Configuration created successfully"

# Validate configuration
print_status "Validating configuration..."
if [ -f "/etc/pterodactyl/config.yml" ]; then
    print_success "Configuration file exists"
    
    # Show configuration
    print_status "Configuration preview:"
    echo "----------------------------------------"
    head -10 /etc/pterodactyl/config.yml
    echo "----------------------------------------"
else
    print_error "Configuration file not created!"
    exit 1
fi

# Check if Wings service exists
if [ -f "/etc/systemd/system/wings.service" ]; then
    print_success "Wings service found"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Start Wings
    print_status "Starting Wings service..."
    systemctl start wings
    
    # Wait a moment
    sleep 3
    
    # Check status
    if systemctl is-active --quiet wings; then
        print_success "Wings started successfully!"
        
        print_status "Wings Status:"
        systemctl status wings --no-pager -l
        
        echo ""
        print_success "🎉 Wings Setup Completed!"
        echo ""
        print_status "📋 Verification:"
        echo "• Wings service: $(systemctl is-active wings)"
        echo "• Configuration: /etc/pterodactyl/config.yml"
        echo "• Data directory: /var/lib/pterodactyl/volumes"
        echo "• API Port: 8080"
        echo "• SFTP Port: 2022"
        echo ""
        print_status "🔧 Useful Commands:"
        echo "• Check status: systemctl status wings"
        echo "• View logs: journalctl -u wings -f"
        echo "• Restart: systemctl restart wings"
        echo "• Stop: systemctl stop wings"
        echo ""
        print_status "🌐 Panel Connection:"
        echo "• Panel URL: http://vpsdos.tams.my.id"
        echo "• Node should now show as online in Admin -> Nodes"
        
    else
        print_error "Wings failed to start!"
        print_status "Checking logs..."
        journalctl -u wings --no-pager -l
        
        echo ""
        print_status "🔧 Troubleshooting:"
        echo "1. Check configuration: cat /etc/pterodactyl/config.yml"
        echo "2. Check Docker: docker --version"
        echo "3. Check logs: journalctl -u wings -f"
        echo "4. Manual start: /usr/local/bin/wings"
        
        exit 1
    fi
    
else
    print_error "Wings service not found!"
    print_status "Creating Wings service..."
    
    cat > /etc/systemd/system/wings.service << 'EOWINGS'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOWINGS
    
    systemctl enable wings
    systemctl daemon-reload
    systemctl start wings
    
    sleep 3
    
    if systemctl is-active --quiet wings; then
        print_success "Wings service created and started!"
    else
        print_error "Failed to start Wings service"
        journalctl -u wings --no-pager -l
        exit 1
    fi
fi

print_success "Wings configuration setup completed successfully!"
