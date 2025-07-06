#!/bin/bash

# 🛠️ Pterodactyl Panel Nginx Fix Script
# Fixes SSL certificate issues and domain configuration

echo "🔧 Starting Pterodactyl Panel Nginx Fix..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
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

# Step 1: Stop nginx service
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

# Step 5: Create new clean nginx configuration
print_status "Creating new nginx configuration for vpsdos.tams.my.id..."
cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name vpsdos.tams.my.id;
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

if curl -s -o /dev/null -w "%{http_code}" http://vpsdos.tams.my.id | grep -q "200\|301\|302"; then
    print_success "Web server is responding!"
else
    print_warning "Web server test inconclusive, checking with localhost..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
        print_success "Web server is responding on localhost!"
        print_warning "Domain might need DNS propagation time"
    else
        print_warning "Web server response test failed, but nginx is running"
    fi
fi

# Step 11: Display status summary
echo ""
echo "================================================"
print_success "🎉 Nginx Fix Completed!"
echo "================================================"
echo ""
print_status "📊 Service Status:"
echo "  • Nginx: $(systemctl is-active nginx)"
echo "  • PHP ${PHP_VERSION}-FPM: $(systemctl is-active php${PHP_VERSION}-fpm)"
echo "  • MySQL: $(systemctl is-active mysql)"
echo ""
print_status "🌐 Access Information:"
echo "  • Panel URL: http://vpsdos.tams.my.id"
echo "  • Username: b82827"
echo "  • Password: b82827"
echo ""
print_status "📝 Next Steps:"
echo "  1. Try accessing: http://vpsdos.tams.my.id"
echo "  2. If working, setup SSL with: certbot --nginx -d vpsdos.tams.my.id"
echo "  3. Create allocations in Nodes section"
echo "  4. Get Wings token and use /startwings command"
echo ""
print_status "🔧 Troubleshooting:"
echo "  • Check logs: tail -f /var/log/nginx/pterodactyl.app-error.log"
echo "  • Test nginx: nginx -t"
echo "  • Restart services: systemctl restart nginx php${PHP_VERSION}-fpm mysql"
echo ""

# Step 12: Final connectivity test
print_status "Performing final connectivity test..."
echo "Testing HTTP response:"
curl -I http://vpsdos.tams.my.id 2>/dev/null || echo "Direct domain test failed"
echo ""
echo "Testing localhost response:"
curl -I http://localhost 2>/dev/null || echo "Localhost test failed"
echo ""

print_success "✅ Fix script completed! Try accessing your panel now."

# Step 13: Check if Pterodactyl directory exists and fix permissions
print_status "Checking Pterodactyl installation..."
if [ -d "/var/www/pterodactyl" ]; then
    print_success "Pterodactyl directory found at /var/www/pterodactyl"

    # Fix permissions
    print_status "Fixing file permissions..."
    chown -R www-data:www-data /var/www/pterodactyl/
    chmod -R 755 /var/www/pterodactyl/
    chmod -R 775 /var/www/pterodactyl/storage/ /var/www/pterodactyl/bootstrap/cache/

    # Check if .env exists
    if [ -f "/var/www/pterodactyl/.env" ]; then
        print_success ".env file exists"
    else
        print_error ".env file missing! This will cause 500 errors."
        if [ -f "/var/www/pterodactyl/.env.example" ]; then
            print_status "Copying .env.example to .env..."
            cp /var/www/pterodactyl/.env.example /var/www/pterodactyl/.env
            chown www-data:www-data /var/www/pterodactyl/.env
        fi
    fi

    # Generate application key if missing
    cd /var/www/pterodactyl
    if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
        print_status "Generating application key..."
        php artisan key:generate --force
    fi

    # Clear cache
    print_status "Clearing application cache..."
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear

    # Check database connection
    print_status "Testing database connection..."
    if php artisan migrate:status >/dev/null 2>&1; then
        print_success "Database connection OK"
    else
        print_warning "Database connection issues detected"
        print_status "You may need to run: php artisan migrate --force"
    fi

else
    print_error "Pterodactyl directory not found at /var/www/pterodactyl!"
    print_status "Checking alternative locations..."
    find /var/www/ -name "artisan" -type f 2>/dev/null | head -5
    find /root/ -name "artisan" -type f 2>/dev/null | head -5
fi

# Step 14: Final test after fixes
print_status "Testing web server after fixes..."
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$HTTP_CODE" = "200" ]; then
    print_success "✅ Web server now responding with HTTP 200!"
elif [ "$HTTP_CODE" = "500" ]; then
    print_error "Still getting HTTP 500 - check Laravel logs:"
    echo "  • tail -f /var/www/pterodactyl/storage/logs/laravel.log"
    echo "  • Check .env database settings"
    echo "  • Run: cd /var/www/pterodactyl && php artisan migrate --force"
else
    print_warning "HTTP response code: $HTTP_CODE"
fi

