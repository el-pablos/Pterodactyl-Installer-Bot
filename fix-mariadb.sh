#!/bin/bash

# 🛠️ MariaDB Specific Fix Script
# Fixes MariaDB authentication issues for Pterodactyl

echo "🔧 Starting MariaDB Fix for Pterodactyl..."
echo "============================================"

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

# Configuration
DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASS="b82827"
ADMIN_USER="b82827"
ADMIN_PASS="b82827"

# Step 1: Stop MariaDB
print_status "Stopping MariaDB service..."
systemctl stop mariadb mysql 2>/dev/null || true
sleep 3

# Step 2: Start MariaDB in safe mode
print_status "Starting MariaDB in safe mode..."
systemctl set-environment MYSQLD_OPTS="--skip-grant-tables --skip-networking"
systemctl start mariadb
sleep 5

# Step 3: Reset root password (MariaDB compatible)
print_status "Resetting MariaDB root password..."
mysql -u root << 'EOF'
USE mysql;
UPDATE user SET password=PASSWORD('b82827') WHERE User='root';
UPDATE user SET plugin='mysql_native_password' WHERE User='root';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    print_success "Root password reset successful"
else
    print_warning "Root password reset failed, trying alternative method..."
    
    # Alternative method for newer MariaDB
    mysql -u root << 'EOF'
USE mysql;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'b82827';
FLUSH PRIVILEGES;
EOF
fi

# Step 4: Restart MariaDB normally
print_status "Restarting MariaDB normally..."
systemctl unset-environment MYSQLD_OPTS
systemctl restart mariadb
sleep 5

# Step 5: Test connection
print_status "Testing MariaDB connection..."
if mysql -u root -pb82827 -e "SELECT 1;" 2>/dev/null; then
    print_success "MariaDB connection successful"
else
    print_error "MariaDB connection failed"
    exit 1
fi

# Step 6: Setup Pterodactyl database
print_status "Setting up Pterodactyl database..."
mysql -u root -pb82827 << 'EOF'
-- Drop existing if exists
DROP USER IF EXISTS 'pterodactyl'@'localhost';
DROP DATABASE IF EXISTS panel;

-- Create database
CREATE DATABASE panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user with proper permissions
CREATE USER 'pterodactyl'@'localhost' IDENTIFIED BY 'b82827';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'localhost';

-- Additional permissions for Laravel
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON panel.* TO 'pterodactyl'@'localhost';
GRANT REFERENCES ON panel.* TO 'pterodactyl'@'localhost';

-- Refresh privileges
FLUSH PRIVILEGES;

-- Test the new user
SELECT 'Database setup completed successfully' as status;
EOF

if [ $? -eq 0 ]; then
    print_success "Database and user created successfully"
else
    print_error "Database setup failed"
    exit 1
fi

# Step 7: Test Pterodactyl user connection
print_status "Testing Pterodactyl user connection..."
if mysql -u pterodactyl -pb82827 panel -e "SELECT 1;" 2>/dev/null; then
    print_success "Pterodactyl user connection successful"
else
    print_error "Pterodactyl user connection failed"
    exit 1
fi

# Step 8: Find and configure Pterodactyl
print_status "Finding Pterodactyl installation..."
PTERODACTYL_PATH=""

if [ -f "/var/www/pterodactyl/artisan" ]; then
    PTERODACTYL_PATH="/var/www/pterodactyl"
elif [ -f "/var/www/html/artisan" ]; then
    PTERODACTYL_PATH="/var/www/html"
else
    print_error "Pterodactyl installation not found!"
    exit 1
fi

print_success "Found Pterodactyl at: $PTERODACTYL_PATH"
cd "$PTERODACTYL_PATH"

# Step 9: Configure .env file
print_status "Configuring .env file..."
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
fi

# Update database configuration
sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_PORT=.*/DB_PORT=3306/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env

# Step 10: Fix permissions and Laravel setup
print_status "Fixing permissions and Laravel setup..."
chown -R www-data:www-data "$PTERODACTYL_PATH"
chmod -R 755 "$PTERODACTYL_PATH"
chmod -R 775 "$PTERODACTYL_PATH/storage" "$PTERODACTYL_PATH/bootstrap/cache"

# Generate application key
php artisan key:generate --force

# Clear caches
php artisan config:clear
php artisan cache:clear
php artisan view:clear

# Step 11: Run migrations
print_status "Running database migrations..."
php artisan migrate --force

if [ $? -ne 0 ]; then
    print_warning "Migration failed, trying reset..."
    php artisan migrate:reset --force
    php artisan migrate --force
fi

# Step 12: Create admin user
print_status "Creating admin user..."
php artisan p:user:make << EOF
admin@panel.local
$ADMIN_USER
$ADMIN_USER
$ADMIN_USER
$ADMIN_PASS
yes
EOF

if [ $? -ne 0 ]; then
    print_warning "Creating admin user via database..."
    mysql -u root -pb82827 panel << EOF
INSERT INTO users (uuid, username, email, name_first, name_last, password, root_admin, language, created_at, updated_at) 
VALUES (
    UUID(),
    '$ADMIN_USER',
    'admin@panel.local',
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

# Step 13: Test final database connection
print_status "Testing final database connection..."
if php artisan migrate:status >/dev/null 2>&1; then
    print_success "Database connection successful"
else
    print_error "Database connection failed"
fi

# Final summary
echo ""
echo "============================================"
print_success "🎉 MariaDB Fix Completed!"
echo "============================================"
echo ""
print_status "📊 Configuration:"
echo "  • Database: $DB_NAME"
echo "  • DB User: $DB_USER"
echo "  • DB Password: $DB_PASS"
echo "  • Admin Username: $ADMIN_USER"
echo "  • Admin Password: $ADMIN_PASS"
echo ""
print_status "🔧 Service Status:"
echo "  • MariaDB: $(systemctl is-active mariadb)"
echo ""

if php artisan migrate:status >/dev/null 2>&1; then
    print_success "✅ SUCCESS! Database is ready!"
    print_status "Now run nginx fix: ./fix-nginx-complete.sh"
else
    print_warning "Database may need additional configuration"
fi
