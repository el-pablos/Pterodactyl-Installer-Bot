#!/bin/bash

# 🚀 Wings Setup Script - Manual Installation
# Usage: ./setup-wings.sh [panel_url] [node_token]

echo "🚀 Pterodactyl Wings Setup Script"
echo "================================="

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

# Get parameters
PANEL_URL=${1:-"http://vpsdos.tams.my.id"}
NODE_TOKEN=${2:-""}

if [ -z "$NODE_TOKEN" ]; then
    print_error "Usage: $0 [panel_url] [node_token]"
    echo ""
    echo "Example:"
    echo "  $0 http://vpsdos.tams.my.id eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9..."
    echo ""
    echo "📋 How to get Wings token:"
    echo "1. Login to your panel: $PANEL_URL"
    echo "2. Go to Admin -> Nodes"
    echo "3. Click on your node"
    echo "4. Go to 'Configuration' tab"
    echo "5. Copy the entire YAML configuration"
    echo ""
    exit 1
fi

print_status "Panel URL: $PANEL_URL"
print_status "Token: ${NODE_TOKEN:0:50}..."

# Step 1: Install Docker if not exists
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_warning "Docker not found, installing..."
    
    # Install Docker
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    systemctl enable --now docker
    
    if command -v docker &> /dev/null; then
        print_success "Docker installed successfully"
    else
        print_error "Docker installation failed"
        exit 1
    fi
else
    print_success "Docker is already installed"
fi

# Step 2: Install Wings
print_status "Installing Wings..."

# Create directory
mkdir -p /etc/pterodactyl

# Download Wings
ARCH=$(dpkg --print-architecture)
print_status "Downloading Wings for architecture: $ARCH"

curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"

if [ $? -eq 0 ]; then
    chmod u+x /usr/local/bin/wings
    print_success "Wings binary downloaded and installed"
else
    print_error "Failed to download Wings"
    exit 1
fi

# Step 3: Create Wings service
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

systemctl enable wings
print_success "Wings service created and enabled"

# Step 4: Configure Wings
print_status "Configuring Wings..."

# Check if token is JWT or full config
if [[ "$NODE_TOKEN" == *"debug:"* ]] || [[ "$NODE_TOKEN" == *"uuid:"* ]]; then
    print_status "Detected full YAML configuration"
    echo "$NODE_TOKEN" > /etc/pterodactyl/config.yml
elif [[ "$NODE_TOKEN" == *"eyJ"* ]]; then
    print_status "Detected JWT token, creating basic configuration"
    
    # Generate UUID for node
    NODE_UUID=$(uuidgen)
    TOKEN_ID=$(uuidgen | cut -d'-' -f1)
    
    cat > /etc/pterodactyl/config.yml << EOF
debug: false
uuid: $NODE_UUID
token_id: $TOKEN_ID
token: $NODE_TOKEN
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
    cert: ""
    key: ""
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
allowed_origins: []
EOF
else
    print_warning "Token format not recognized, creating basic config anyway..."
    
    NODE_UUID=$(uuidgen)
    TOKEN_ID=$(uuidgen | cut -d'-' -f1)
    
    cat > /etc/pterodactyl/config.yml << EOF
debug: false
uuid: $NODE_UUID
token_id: $TOKEN_ID
token: $NODE_TOKEN
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
allowed_origins: []
EOF
fi

# Set permissions
chown -R root:root /etc/pterodactyl
chmod -R 755 /etc/pterodactyl

print_success "Wings configuration created"

# Step 5: Create data directory
print_status "Creating Wings data directory..."
mkdir -p /var/lib/pterodactyl/volumes
chown -R root:root /var/lib/pterodactyl

# Step 6: Start Wings
print_status "Starting Wings service..."
systemctl start wings

# Wait a moment for service to start
sleep 3

# Check service status
if systemctl is-active --quiet wings; then
    print_success "Wings service started successfully!"
    
    # Show status
    echo ""
    print_status "Wings Status:"
    systemctl status wings --no-pager -l
    
    echo ""
    print_success "🎉 Wings Setup Completed!"
    echo ""
    print_status "📋 Next Steps:"
    echo "1. Check Wings logs: journalctl -u wings -f"
    echo "2. Verify connection in your panel"
    echo "3. Create allocations for your servers"
    echo ""
    print_status "🔧 Useful Commands:"
    echo "• Start Wings: systemctl start wings"
    echo "• Stop Wings: systemctl stop wings"
    echo "• Restart Wings: systemctl restart wings"
    echo "• View logs: journalctl -u wings -f"
    echo "• Check status: systemctl status wings"
    
else
    print_error "Wings service failed to start!"
    echo ""
    print_status "Checking logs..."
    journalctl -u wings --no-pager -l
    
    echo ""
    print_status "🔧 Troubleshooting:"
    echo "1. Check config: cat /etc/pterodactyl/config.yml"
    echo "2. Check logs: journalctl -u wings -f"
    echo "3. Verify Docker: docker --version"
    echo "4. Check token format in panel"
    
    exit 1
fi
