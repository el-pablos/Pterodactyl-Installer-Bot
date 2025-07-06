#!/bin/bash

# 🚀 Complete Wings Fix Script
# Fixes all Wings configuration and permission issues

echo "🚀 Complete Wings Fix Script"
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

# Step 1: Stop Wings if running
print_status "Stopping Wings service..."
systemctl stop wings 2>/dev/null || true

# Step 2: Check if Wings binary exists
if [ ! -f "/usr/local/bin/wings" ]; then
    print_warning "Wings binary not found, downloading..."
    
    # Download Wings
    ARCH=$(dpkg --print-architecture)
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"
    chmod u+x /usr/local/bin/wings
    
    if [ -f "/usr/local/bin/wings" ]; then
        print_success "Wings binary downloaded"
    else
        print_error "Failed to download Wings binary"
        exit 1
    fi
else
    print_success "Wings binary found"
fi

# Step 3: Create directories
print_status "Creating required directories..."
mkdir -p /etc/pterodactyl
mkdir -p /var/lib/pterodactyl/volumes
mkdir -p /var/lib/pterodactyl/archives
mkdir -p /var/lib/pterodactyl/backups
mkdir -p /var/log/pterodactyl
mkdir -p /tmp/pterodactyl
mkdir -p /var/run/wings

print_success "Directories created"

# Step 4: Create simple Wings configuration
print_status "Creating simplified Wings configuration..."

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

print_success "Configuration created"

# Step 5: Set proper permissions (run as root for simplicity)
print_status "Setting permissions..."
chown -R root:root /etc/pterodactyl
chown -R root:root /var/lib/pterodactyl
chown -R root:root /var/log/pterodactyl
chown -R root:root /tmp/pterodactyl
chown -R root:root /var/run/wings

chmod -R 755 /etc/pterodactyl
chmod -R 755 /var/lib/pterodactyl

print_success "Permissions set"

# Step 6: Create Wings systemd service
print_status "Creating Wings systemd service..."

cat > /etc/systemd/system/wings.service << 'EOF'
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
EOF

systemctl daemon-reload
systemctl enable wings

print_success "Wings service created"

# Step 7: Check Docker
print_status "Checking Docker..."
if systemctl is-active --quiet docker; then
    print_success "Docker is running"
else
    print_warning "Docker is not running, starting..."
    systemctl start docker
    systemctl enable docker
    
    if systemctl is-active --quiet docker; then
        print_success "Docker started"
    else
        print_error "Failed to start Docker"
        exit 1
    fi
fi

# Step 8: Test Wings configuration
print_status "Testing Wings configuration..."

# Test Wings binary
if /usr/local/bin/wings --version >/dev/null 2>&1; then
    print_success "Wings binary is working"
else
    print_error "Wings binary test failed"
    exit 1
fi

# Step 9: Start Wings
print_status "Starting Wings service..."
systemctl start wings

# Wait a moment
sleep 5

# Check status
if systemctl is-active --quiet wings; then
    print_success "Wings started successfully!"
    
    print_status "Wings Status:"
    systemctl status wings --no-pager -l
    
    echo ""
    print_success "🎉 Wings Fix Completed!"
    echo ""
    print_status "📋 Verification:"
    echo "• Wings service: $(systemctl is-active wings)"
    echo "• Docker service: $(systemctl is-active docker)"
    echo "• Configuration: /etc/pterodactyl/config.yml"
    echo "• Data directory: /var/lib/pterodactyl/volumes"
    echo "• API Port: 8080"
    echo "• SFTP Port: 2022"
    echo ""
    print_status "🔧 Useful Commands:"
    echo "• Check status: systemctl status wings"
    echo "• View logs: journalctl -u wings -f"
    echo "• Restart: systemctl restart wings"
    echo "• Manual test: /usr/local/bin/wings --debug"
    echo ""
    print_status "🌐 Panel Connection:"
    echo "• Panel URL: http://vpsdos.tams.my.id"
    echo "• Node should now show as online in Admin -> Nodes"
    
else
    print_error "Wings failed to start!"
    
    print_status "Checking logs..."
    journalctl -u wings --no-pager -l
    
    print_status "Testing manual start..."
    echo "Running: /usr/local/bin/wings --debug"
    echo "Press Ctrl+C to stop manual test"
    echo ""
    
    # Try manual start for debugging
    /usr/local/bin/wings --debug
fi
