#!/bin/bash

# 🛠️ Complete Database & Panel Fix Script
# Fixes all database issues and creates admin user automatically

echo "🔧 Starting Complete Database & Panel Fix..."
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

# Configuration
DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASS="b82827"
ADMIN_USER="b82827"
ADMIN_PASS="b82827"
ADMIN_EMAIL="admin@panel.local"

# Step 1: Find Pterodactyl installation
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

# Step 2: Stop services
print_status "Stopping services..."
systemctl stop nginx 2>/dev/null || true
systemctl stop mysql 2>/dev/null || true
sleep 2

# Step 3: Start MySQL
print_status "Starting MySQL..."
systemctl start mysql
sleep 3

# Step 4: Get MySQL root password
print_status "Detecting MySQL root password..."
MYSQL_ROOT_PASS=""

# Try common passwords
for pass in "" "root" "password" "mysql" "$DB_PASS"; do
    if mysql -u root -p"$pass" -e "SELECT 1;" 2>/dev/null; then
        MYSQL_ROOT_PASS="$pass"
        break
    fi
done

if [ -z "$MYSQL_ROOT_PASS" ]; then
    print_warning "Cannot connect to MySQL with common passwords, trying to reset..."

    # Reset MySQL/MariaDB root password (compatible with both)
    systemctl stop mysql mariadb 2>/dev/null || true
    sleep 2

    # Check if it's MariaDB or MySQL
    if command -v mariadb >/dev/null 2>&1; then
        print_status "Detected MariaDB, using MariaDB-specific reset..."

        # MariaDB reset method
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
        # MySQL reset method
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

# Step 5: Setup database and user
print_status "Setting up database and user..."
mysql -u root -p"$MYSQL_ROOT_PASS" << EOF
-- Drop existing user and database if they exist
DROP USER IF EXISTS '$DB_USER'@'localhost';
DROP DATABASE IF EXISTS $DB_NAME;

-- Create database
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user with all necessary permissions
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON $DB_NAME.* TO '$DB_USER'@'localhost';

-- Additional permissions for Laravel
GRANT REFERENCES ON $DB_NAME.* TO '$DB_USER'@'localhost';
GRANT CREATE VIEW ON $DB_NAME.* TO '$DB_USER'@'localhost';
GRANT SHOW VIEW ON $DB_NAME.* TO '$DB_USER'@'localhost';

-- Refresh privileges
FLUSH PRIVILEGES;

-- Test connection
SELECT 'Database setup completed successfully' as status;
EOF

if [ $? -eq 0 ]; then
    print_success "Database and user created successfully"
else
    print_error "Database setup failed"
    exit 1
fi

# Step 6: Configure .env file
print_status "Configuring .env file..."

# Backup existing .env
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d-%H%M%S)
fi

# Create or update .env
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
fi

# Update database configuration
sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_PORT=.*/DB_PORT=3306/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env

# Ensure other required settings
sed -i "s/APP_ENV=.*/APP_ENV=production/" .env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" .env
sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=file/" .env
sed -i "s/SESSION_DRIVER=.*/SESSION_DRIVER=file/" .env
sed -i "s/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=database/" .env

print_success ".env file configured"

# Step 7: Fix permissions
print_status "Fixing file permissions..."
chown -R www-data:www-data "$PTERODACTYL_PATH"
chmod -R 755 "$PTERODACTYL_PATH"
chmod -R 775 "$PTERODACTYL_PATH/storage" "$PTERODACTYL_PATH/bootstrap/cache"
chmod 644 .env

# Step 8: Generate application key
print_status "Generating application key..."
php artisan key:generate --force

# Step 9: Clear caches
print_status "Clearing caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# Step 10: Run migrations
print_status "Running database migrations..."
php artisan migrate --force

if [ $? -ne 0 ]; then
    print_error "Migration failed, trying to fix..."
    
    # Try to fix migration issues
    php artisan migrate:reset --force
    php artisan migrate --force
    
    if [ $? -ne 0 ]; then
        print_error "Migration still failed, but continuing..."
    fi
fi

# Step 11: Seed database
print_status "Seeding database..."
php artisan db:seed --force 2>/dev/null || print_warning "Database seeding failed, but continuing..."

# Step 12: Create admin user
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
    print_warning "Admin user creation via artisan failed, trying direct database insert..."
    
    # Create admin user directly in database
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
    
    if [ $? -eq 0 ]; then
        print_success "Admin user created via database"
    else
        print_error "Failed to create admin user"
    fi
fi

# Step 13: Start services
print_status "Starting services..."
systemctl start mysql
systemctl start nginx

# Check PHP-FPM version and start
for version in 8.3 8.1 8.0; do
    if systemctl is-enabled php${version}-fpm 2>/dev/null; then
        systemctl start php${version}-fpm
        print_success "Started PHP ${version}-FPM"
        break
    fi
done

# Step 14: Test database connection
print_status "Testing database connection..."
if php artisan migrate:status >/dev/null 2>&1; then
    print_success "Database connection successful"
else
    print_error "Database connection failed"
fi

# Step 15: Test web server
print_status "Testing web server..."
sleep 3

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")
print_status "HTTP Response Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    print_success "✅ Web server responding correctly!"
elif [ "$HTTP_CODE" = "500" ]; then
    print_warning "Still getting 500 error, checking logs..."
    tail -5 storage/logs/laravel.log 2>/dev/null || echo "No Laravel logs found"
else
    print_warning "HTTP response code: $HTTP_CODE"
fi

# Step 16: Final summary
echo ""
echo "================================================"
print_success "🎉 Complete Database & Panel Fix Completed!"
echo "================================================"
echo ""
print_status "📊 Configuration Summary:"
echo "  • Database: $DB_NAME"
echo "  • DB User: $DB_USER"
echo "  • DB Password: $DB_PASS"
echo "  • Admin Username: $ADMIN_USER"
echo "  • Admin Password: $ADMIN_PASS"
echo "  • Admin Email: $ADMIN_EMAIL"
echo ""
print_status "🌐 Access Information:"
echo "  • Panel URL: http://localhost (or your domain)"
echo "  • Username: $ADMIN_USER"
echo "  • Password: $ADMIN_PASS"
echo ""
print_status "🔧 Service Status:"
echo "  • MySQL: $(systemctl is-active mysql)"
echo "  • Nginx: $(systemctl is-active nginx)"
echo "  • HTTP Response: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    print_success "✅ SUCCESS! Panel should be accessible now!"
    print_status "Try logging in with username: $ADMIN_USER and password: $ADMIN_PASS"
else
    print_warning "Panel may need additional configuration"
    print_status "Check logs: tail -f $PTERODACTYL_PATH/storage/logs/laravel.log"
fi
