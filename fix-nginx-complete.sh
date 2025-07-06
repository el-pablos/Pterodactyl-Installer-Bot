#!/bin/bash

# 🛠️ Complete Nginx & SSL Fix Script
# Fixes all nginx configuration issues and SSL problems

echo "🔧 Starting Complete Nginx & SSL Fix..."
echo "================================================"

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

# Configuration - Update these with your actual domains
PANEL_DOMAIN="vpsdos.tams.my.id"
NODE_DOMAIN="node-vpsdos.tams.my.id"

# Step 1: Stop nginx
print_status "Stopping nginx service..."
systemctl stop nginx
sleep 2

# Step 2: Backup existing configurations
print_status "Backing up existing configurations..."
mkdir -p /root/nginx-backup-$(date +%Y%m%d-%H%M%S)
cp -r /etc/nginx/sites-available/ /root/nginx-backup-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null
cp -r /etc/nginx/sites-enabled/ /root/nginx-backup-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null

# Step 3: Remove all conflicting configurations
print_status "Removing conflicting configurations..."
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/sites-available/pterodactyl.conf
rm -f /etc/nginx/sites-available/default

# Step 4: Detect PHP version
print_status "Detecting PHP version..."
PHP_VERSION=""
if [ -S "/run/php/php8.3-fpm.sock" ]; then
    PHP_VERSION="8.3"
    print_success "Found PHP 8.3"
elif [ -S "/run/php/php8.1-fpm.sock" ]; then
    PHP_VERSION="8.1"
    print_success "Found PHP 8.1"
elif [ -S "/run/php/php8.0-fpm.sock" ]; then
    PHP_VERSION="8.0"
    print_success "Found PHP 8.0"
else
    print_error "No PHP-FPM socket found!"
    ls -la /run/php/
    exit 1
fi

# Step 5: Create clean nginx configuration for HTTP first
print_status "Creating HTTP nginx configuration for $PANEL_DOMAIN..."
cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $PANEL_DOMAIN;
    root /var/www/pterodactyl/public;
    index index.php;
    
    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;
    
    # Allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;
    
    sendfile off;
    
    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \\n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    
    location ~ /\.ht {
        deny all;
    }
    
    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
    }
    
    location = /robots.txt  { 
        access_log off; 
        log_not_found off; 
    }
}
EOF

# Step 6: Enable the configuration
print_status "Enabling nginx configuration..."
ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/

# Step 7: Test nginx configuration
print_status "Testing nginx configuration..."
if nginx -t; then
    print_success "Nginx configuration is valid!"
else
    print_error "Nginx configuration test failed!"
    nginx -t
    exit 1
fi

# Step 8: Ensure required services are running
print_status "Checking and starting required services..."

# Check MySQL
if systemctl is-active --quiet mysql; then
    print_success "MySQL is running"
else
    print_status "Starting MySQL..."
    systemctl start mysql
    if systemctl is-active --quiet mysql; then
        print_success "MySQL started successfully"
    else
        print_warning "MySQL failed to start, but continuing..."
    fi
fi

# Check PHP-FPM
if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
    print_success "PHP ${PHP_VERSION}-FPM is running"
else
    print_status "Starting PHP ${PHP_VERSION}-FPM..."
    systemctl start php${PHP_VERSION}-fpm
    if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
        print_success "PHP ${PHP_VERSION}-FPM started successfully"
    else
        print_error "PHP ${PHP_VERSION}-FPM failed to start!"
        systemctl status php${PHP_VERSION}-fpm
        exit 1
    fi
fi

# Step 9: Start nginx
print_status "Starting nginx..."
systemctl start nginx

if systemctl is-active --quiet nginx; then
    print_success "Nginx started successfully!"
else
    print_error "Nginx failed to start!"
    systemctl status nginx
    exit 1
fi

# Step 10: Test web server response
print_status "Testing web server response..."
sleep 3

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    print_success "Web server is responding!"
    
    # Test domain response
    DOMAIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$PANEL_DOMAIN 2>/dev/null || echo "000")
    if [ "$DOMAIN_CODE" = "200" ]; then
        print_success "Domain is responding!"
    else
        print_warning "Domain not responding (DNS may need time to propagate)"
    fi
else
    print_warning "Web server test failed with code: $HTTP_CODE"
fi

# Step 11: Setup SSL if domain is working
if [ "$DOMAIN_CODE" = "200" ] || [ "$HTTP_CODE" = "200" ]; then
    print_status "Setting up SSL certificate..."
    
    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        print_status "Installing certbot..."
        apt-get update -y
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Generate SSL certificate
    print_status "Generating SSL certificate for $PANEL_DOMAIN..."
    certbot --nginx -d $PANEL_DOMAIN --non-interactive --agree-tos --email admin@$PANEL_DOMAIN --redirect
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificate generated successfully!"
        
        # Test HTTPS
        sleep 3
        HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$PANEL_DOMAIN 2>/dev/null || echo "000")
        if [ "$HTTPS_CODE" = "200" ]; then
            print_success "HTTPS is working!"
        else
            print_warning "HTTPS test failed, but HTTP should work"
        fi
    else
        print_warning "SSL certificate generation failed, but HTTP should work"
    fi
fi

# Step 12: Display status summary
echo ""
echo "================================================"
print_success "🎉 Nginx & SSL Fix Completed!"
echo "================================================"
echo ""
print_status "📊 Service Status:"
echo "  • Nginx: $(systemctl is-active nginx)"
echo "  • PHP ${PHP_VERSION}-FPM: $(systemctl is-active php${PHP_VERSION}-fpm)"
echo "  • MySQL: $(systemctl is-active mysql)"
echo ""
print_status "🌐 Access Information:"
echo "  • HTTP URL: http://$PANEL_DOMAIN"
if [ "$HTTPS_CODE" = "200" ]; then
    echo "  • HTTPS URL: https://$PANEL_DOMAIN"
fi
echo "  • Username: b82827"
echo "  • Password: b82827"
echo ""
print_status "📝 Next Steps:"
echo "  1. Try accessing: http://$PANEL_DOMAIN"
if [ "$HTTPS_CODE" != "200" ]; then
    echo "  2. If HTTP works, SSL can be setup later with: certbot --nginx -d $PANEL_DOMAIN"
fi
echo "  3. Create allocations in Nodes section"
echo "  4. Get Wings token and use /startwings command"
echo ""
print_status "🔧 Troubleshooting:"
echo "  • Check logs: tail -f /var/log/nginx/pterodactyl.app-error.log"
echo "  • Test nginx: nginx -t"
echo "  • Restart services: systemctl restart nginx php${PHP_VERSION}-fpm mysql"
echo ""

# Step 13: Final connectivity test
print_status "Performing final connectivity test..."
echo "Testing HTTP response:"
curl -I http://$PANEL_DOMAIN 2>/dev/null || echo "Domain test failed"
echo ""
echo "Testing localhost response:"
curl -I http://localhost 2>/dev/null || echo "Localhost test failed"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    print_success "✅ SUCCESS! Panel should be accessible now!"
else
    print_warning "Panel may need additional configuration"
fi
