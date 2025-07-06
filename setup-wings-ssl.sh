#!/bin/bash

# 🔐 Wings SSL Certificate Setup Script
# Usage: ./setup-wings-ssl.sh [node_domain]

echo "🔐 Wings SSL Certificate Setup"
echo "=============================="

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

# Get domain parameter
NODE_DOMAIN=${1:-"node-vpsdos.tams.my.id"}

print_status "Setting up SSL for domain: $NODE_DOMAIN"

# Step 1: Check if domain resolves to this server
print_status "Checking domain resolution..."
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $NODE_DOMAIN | tail -n1)

if [ "$SERVER_IP" = "$DOMAIN_IP" ]; then
    print_success "Domain resolves correctly to this server ($SERVER_IP)"
else
    print_warning "Domain resolution mismatch!"
    print_status "Server IP: $SERVER_IP"
    print_status "Domain IP: $DOMAIN_IP"
    print_status "Please update DNS A record: $NODE_DOMAIN -> $SERVER_IP"
    
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 2: Install certbot if not exists
print_status "Installing certbot..."
if ! command -v certbot &> /dev/null; then
    apt update
    apt install -y certbot
    
    if command -v certbot &> /dev/null; then
        print_success "Certbot installed"
    else
        print_error "Failed to install certbot"
        exit 1
    fi
else
    print_success "Certbot already installed"
fi

# Step 3: Stop Wings temporarily
print_status "Stopping Wings temporarily..."
systemctl stop wings

# Step 4: Generate SSL certificate
print_status "Generating SSL certificate for $NODE_DOMAIN..."

# Check if certificate already exists
if [ -d "/etc/letsencrypt/live/$NODE_DOMAIN" ]; then
    print_warning "Certificate already exists for $NODE_DOMAIN"
    read -p "Renew certificate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        certbot renew --cert-name $NODE_DOMAIN
    fi
else
    # Generate new certificate
    certbot certonly --standalone -d $NODE_DOMAIN --non-interactive --agree-tos --email admin@$NODE_DOMAIN
fi

# Check if certificate was created
if [ -f "/etc/letsencrypt/live/$NODE_DOMAIN/fullchain.pem" ]; then
    print_success "SSL certificate generated successfully"
else
    print_error "Failed to generate SSL certificate"
    print_status "Trying alternative method..."
    
    # Try with nginx if available
    if command -v nginx &> /dev/null; then
        systemctl start nginx
        certbot --nginx -d $NODE_DOMAIN --non-interactive --agree-tos --email admin@$NODE_DOMAIN
        systemctl stop nginx
    fi
    
    if [ ! -f "/etc/letsencrypt/live/$NODE_DOMAIN/fullchain.pem" ]; then
        print_error "SSL certificate generation failed"
        print_status "Continuing with HTTP configuration..."
        SSL_ENABLED=false
    else
        SSL_ENABLED=true
    fi
else
    SSL_ENABLED=true
fi

# Step 5: Update Wings configuration
print_status "Updating Wings configuration..."

if [ "$SSL_ENABLED" = true ]; then
    print_status "Configuring Wings with SSL enabled"
    
    cat > /etc/pterodactyl/config.yml << EOF
debug: false
uuid: 2b372615-d696-43ae-b2e2-24d756377252
token_id: bCkM3gV3BNFTiNeS
token: mxSpfA8eSVvNw4woCs3Zx4ABq6SQMorVzxRpl7qQozo7isHvpQp13ns1l4ndbQJz
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/letsencrypt/live/$NODE_DOMAIN/fullchain.pem
    key: /etc/letsencrypt/live/$NODE_DOMAIN/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: 'https://vpsdos.tams.my.id'
EOF

else
    print_status "Configuring Wings with SSL disabled"
    
    cat > /etc/pterodactyl/config.yml << EOF
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

fi

print_success "Wings configuration updated"

# Step 6: Set certificate permissions
if [ "$SSL_ENABLED" = true ]; then
    print_status "Setting certificate permissions..."
    chown -R root:root /etc/letsencrypt
    chmod -R 755 /etc/letsencrypt
fi

# Step 7: Start Wings
print_status "Starting Wings..."
systemctl start wings

# Wait a moment
sleep 3

# Check status
if systemctl is-active --quiet wings; then
    print_success "Wings started successfully with SSL!"
    
    echo ""
    print_success "🎉 SSL Setup Completed!"
    echo ""
    
    if [ "$SSL_ENABLED" = true ]; then
        print_status "📋 SSL Configuration:"
        echo "• Domain: $NODE_DOMAIN"
        echo "• SSL: Enabled"
        echo "• Certificate: /etc/letsencrypt/live/$NODE_DOMAIN/fullchain.pem"
        echo "• Private Key: /etc/letsencrypt/live/$NODE_DOMAIN/privkey.pem"
        echo "• Wings API: https://$NODE_DOMAIN:8080"
        
        print_status "🔧 Panel Configuration:"
        echo "1. Login to panel: https://vpsdos.tams.my.id"
        echo "2. Go to Admin → Nodes"
        echo "3. Edit your node with these settings:"
        echo "   • FQDN: $NODE_DOMAIN"
        echo "   • Communicate Over SSL: Yes"
        echo "   • Daemon Port: 8080"
        
        print_status "🔄 Certificate Auto-Renewal:"
        echo "• Certificates will auto-renew via cron"
        echo "• Manual renewal: certbot renew"
        echo "• Check expiry: certbot certificates"
        
    else
        print_warning "SSL setup failed, using HTTP configuration"
        echo "• Wings API: http://$NODE_DOMAIN:8080"
        echo "• Panel node setting: Communicate Over SSL = No"
    fi
    
    print_status "🔧 Useful Commands:"
    echo "• Check Wings: systemctl status wings"
    echo "• View logs: journalctl -u wings -f"
    echo "• Test SSL: curl -I https://$NODE_DOMAIN:8080"
    
else
    print_error "Wings failed to start!"
    print_status "Checking logs..."
    journalctl -u wings --no-pager -l
    
    print_status "🔧 Troubleshooting:"
    echo "1. Check certificate: ls -la /etc/letsencrypt/live/$NODE_DOMAIN/"
    echo "2. Test manual: /usr/local/bin/wings --debug"
    echo "3. Check config: cat /etc/pterodactyl/config.yml"
fi
