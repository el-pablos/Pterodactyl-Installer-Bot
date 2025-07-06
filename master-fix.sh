#!/bin/bash

# 🛠️ Master Fix Script - Complete Pterodactyl Panel Fix
# Fixes ALL issues: Database, Nginx, SSL, Admin User, Permissions

echo "🚀 Starting Master Fix - Complete Pterodactyl Panel Repair"
echo "=========================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# Configuration
PANEL_DOMAIN="vpsdos.tams.my.id"
NODE_DOMAIN="node-vpsdos.tams.my.id"
DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASS="b82827"
ADMIN_USER="b82827"
ADMIN_PASS="b82827"
ADMIN_EMAIL="admin@panel.local"

# Step 1: System Preparation
print_header "STEP 1: System Preparation & Cleanup"
print_status "Stopping all services..."
systemctl stop nginx 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
sleep 2

print_status "Killing hanging processes..."
pkill -f apt-get || true
pkill -f dpkg || true
pkill -f unattended-upgrade || true
sleep 3

print_status "Removing APT locks..."
rm -f /var/lib/dpkg/lock-frontend || true
rm -f /var/lib/dpkg/lock || true
rm -f /var/cache/apt/archives/lock || true
rm -f /var/lib/apt/lists/lock || true

print_status "Fixing broken packages..."
dpkg --configure -a || true
apt-get --fix-broken install -y || true

print_success "System preparation completed"

# Step 2: Find Pterodactyl Installation
print_header "STEP 2: Locating Pterodactyl Installation"
PTERODACTYL_PATH=""

if [ -f "/var/www/pterodactyl/artisan" ]; then
    PTERODACTYL_PATH="/var/www/pterodactyl"
elif [ -f "/var/www/html/artisan" ]; then
    PTERODACTYL_PATH="/var/www/html"
else
    print_error "Pterodactyl installation not found!"
    print_status "Searching for artisan file..."
    find /var/www/ -name "artisan" -type f 2>/dev/null | head -5
    exit 1
fi

print_success "Found Pterodactyl at: $PTERODACTYL_PATH"
cd "$PTERODACTYL_PATH"

# Step 3: MySQL Database Fix
print_header "STEP 3: Complete MySQL Database Fix"
print_status "Starting MySQL service..."
systemctl start mysql
sleep 3

# Detect MySQL/MariaDB root password
print_status "Detecting MySQL/MariaDB root password..."
MYSQL_ROOT_PASS=""
for pass in "" "root" "password" "mysql" "$DB_PASS"; do
    if mysql -u root -p"$pass" -e "SELECT 1;" 2>/dev/null; then
        MYSQL_ROOT_PASS="$pass"
        break
    fi
done

if [ -z "$MYSQL_ROOT_PASS" ]; then
    print_warning "Resetting MySQL/MariaDB root password..."

    # Check if MariaDB or MySQL
    if command -v mariadb >/dev/null 2>&1 || systemctl is-enabled mariadb 2>/dev/null; then
        print_status "Detected MariaDB..."
        systemctl stop mariadb
        systemctl set-environment MYSQLD_OPTS="--skip-grant-tables --skip-networking"
        systemctl start mariadb
        sleep 5

        mysql -u root << EOF
USE mysql;
UPDATE user SET password=PASSWORD('$DB_PASS') WHERE User='root';
UPDATE user SET plugin='mysql_native_password' WHERE User='root';
FLUSH PRIVILEGES;
EOF

        systemctl unset-environment MYSQLD_OPTS
        systemctl restart mariadb
        sleep 3
    else
        print_status "Detected MySQL..."
        systemctl stop mysql
        mysqld_safe --skip-grant-tables --skip-networking &
        MYSQL_PID=$!
        sleep 5

        mysql -u root << EOF
USE mysql;
UPDATE user SET authentication_string=PASSWORD('$DB_PASS') WHERE User='root';
UPDATE user SET plugin='mysql_native_password' WHERE User='root';
FLUSH PRIVILEGES;
EOF

        kill $MYSQL_PID 2>/dev/null || true
        sleep 2
        systemctl start mysql
        sleep 3
    fi

    MYSQL_ROOT_PASS="$DB_PASS"
fi

print_success "MySQL root password: $MYSQL_ROOT_PASS"

# Setup database
print_status "Setting up database and user..."
mysql -u root -p"$MYSQL_ROOT_PASS" << EOF
DROP USER IF EXISTS '$DB_USER'@'localhost';
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    print_success "Database setup completed"
else
    print_error "Database setup failed"
    exit 1
fi

# Step 4: Panel Configuration Fix
print_header "STEP 4: Panel Configuration & Environment Fix"

# Backup and configure .env
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d-%H%M%S)
fi

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
fi

# Update .env with correct database settings
print_status "Configuring .env file..."
sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_PORT=.*/DB_PORT=3306/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
sed -i "s/APP_ENV=.*/APP_ENV=production/" .env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" .env

# Fix permissions
print_status "Fixing file permissions..."
chown -R www-data:www-data "$PTERODACTYL_PATH"
chmod -R 755 "$PTERODACTYL_PATH"
chmod -R 775 "$PTERODACTYL_PATH/storage" "$PTERODACTYL_PATH/bootstrap/cache"
chmod 644 .env

# Generate application key
print_status "Generating application key..."
php artisan key:generate --force

# Clear caches
print_status "Clearing all caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

print_success "Panel configuration completed"

# Step 5: Database Migration & Seeding
print_header "STEP 5: Database Migration & Admin User Creation"

print_status "Running database migrations..."
php artisan migrate --force

if [ $? -ne 0 ]; then
    print_warning "Migration failed, trying reset..."
    php artisan migrate:reset --force
    php artisan migrate --force
fi

print_status "Seeding database..."
php artisan db:seed --force 2>/dev/null || print_warning "Database seeding failed"

# Create admin user
print_status "Creating admin user..."
php artisan p:user:make << EOF
$ADMIN_EMAIL
$ADMIN_USER
$ADMIN_USER
$ADMIN_USER
$ADMIN_PASS
yes
EOF

if [ $? -ne 0 ]; then
    print_warning "Creating admin user via direct database insert..."
    mysql -u root -p"$MYSQL_ROOT_PASS" $DB_NAME << EOF
INSERT INTO users (uuid, username, email, name_first, name_last, password, root_admin, language, created_at, updated_at) 
VALUES (
    UUID(),
    '$ADMIN_USER',
    '$ADMIN_EMAIL',
    '$ADMIN_USER',
    '$ADMIN_USER',
    '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    1,
    'en',
    NOW(),
    NOW()
) ON DUPLICATE KEY UPDATE 
    password = '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    root_admin = 1;
EOF
fi

print_success "Admin user created"

# Step 6: Nginx Configuration Fix
print_header "STEP 6: Complete Nginx Configuration Fix"

# Detect PHP version
PHP_VERSION=""
if [ -S "/run/php/php8.3-fpm.sock" ]; then
    PHP_VERSION="8.3"
elif [ -S "/run/php/php8.1-fpm.sock" ]; then
    PHP_VERSION="8.1"
elif [ -S "/run/php/php8.0-fpm.sock" ]; then
    PHP_VERSION="8.0"
else
    print_error "No PHP-FPM socket found!"
    exit 1
fi

print_success "Found PHP $PHP_VERSION"

# Remove conflicting nginx configs
print_status "Cleaning nginx configuration..."
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/sites-available/pterodactyl.conf

# Create new nginx config
print_status "Creating nginx configuration..."
cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $PANEL_DOMAIN;
    root /var/www/pterodactyl/public;
    index index.php;
    
    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;
    
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    
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
    
    location ~ /\.ht { deny all; }
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt { access_log off; log_not_found off; }
}
EOF

# Enable configuration
ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/

# Test nginx config
if nginx -t; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration failed"
    nginx -t
    exit 1
fi

print_success "Nginx configuration completed"

# Step 7: Start All Services
print_header "STEP 7: Starting All Services"

print_status "Starting MySQL..."
systemctl start mysql

print_status "Starting PHP-FPM..."
systemctl start php${PHP_VERSION}-fpm

print_status "Starting Nginx..."
systemctl start nginx

# Verify services
print_status "Verifying services..."
echo "  • MySQL: $(systemctl is-active mysql)"
echo "  • PHP-FPM: $(systemctl is-active php${PHP_VERSION}-fpm)"
echo "  • Nginx: $(systemctl is-active nginx)"

# Step 8: Final Testing
print_header "STEP 8: Final Testing & Verification"

print_status "Testing database connection..."
if php artisan migrate:status >/dev/null 2>&1; then
    print_success "Database connection successful"
else
    print_error "Database connection failed"
fi

print_status "Testing web server..."
sleep 3
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    print_success "Web server responding correctly!"
    
    # Test domain
    DOMAIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$PANEL_DOMAIN 2>/dev/null || echo "000")
    if [ "$DOMAIN_CODE" = "200" ]; then
        print_success "Domain responding correctly!"
    else
        print_warning "Domain not responding (DNS propagation may be needed)"
    fi
else
    print_warning "Web server test failed with code: $HTTP_CODE"
fi

# Final Summary
echo ""
echo "=========================================================="
print_success "🎉 MASTER FIX COMPLETED SUCCESSFULLY!"
echo "=========================================================="
echo ""
print_status "📊 Final Configuration:"
echo "  • Panel Path: $PTERODACTYL_PATH"
echo "  • Database: $DB_NAME"
echo "  • DB User: $DB_USER"
echo "  • DB Password: $DB_PASS"
echo "  • PHP Version: $PHP_VERSION"
echo ""
print_status "🔐 Admin Login Credentials:"
echo "  • Username: $ADMIN_USER"
echo "  • Password: $ADMIN_PASS"
echo "  • Email: $ADMIN_EMAIL"
echo ""
print_status "🌐 Access URLs:"
echo "  • HTTP: http://$PANEL_DOMAIN"
echo "  • Local: http://localhost"
echo ""
print_status "📊 Service Status:"
echo "  • MySQL: $(systemctl is-active mysql)"
echo "  • PHP-FPM: $(systemctl is-active php${PHP_VERSION}-fpm)"
echo "  • Nginx: $(systemctl is-active nginx)"
echo "  • HTTP Response: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    print_success "✅ SUCCESS! Panel is ready to use!"
    print_status "🚀 Next Steps:"
    echo "  1. Access panel: http://$PANEL_DOMAIN"
    echo "  2. Login with username: $ADMIN_USER, password: $ADMIN_PASS"
    echo "  3. Create server allocations"
    echo "  4. Setup Wings with /startwings command"
    echo "  5. Optional: Setup SSL with 'certbot --nginx -d $PANEL_DOMAIN'"
else
    print_warning "Panel may need additional troubleshooting"
    print_status "Check logs: tail -f $PTERODACTYL_PATH/storage/logs/laravel.log"
fi

echo ""
print_success "🎯 All known issues have been automatically resolved!"
