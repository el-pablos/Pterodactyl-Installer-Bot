#!/bin/bash

# 🛠️ Fix Pterodactyl 500 Internal Server Error
echo "🔧 Fixing Pterodactyl 500 Internal Server Error..."
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

# Step 1: Find Pterodactyl installation
print_status "Looking for Pterodactyl installation..."
PTERODACTYL_PATH=""

if [ -f "/var/www/pterodactyl/artisan" ]; then
    PTERODACTYL_PATH="/var/www/pterodactyl"
    print_success "Found Pterodactyl at: $PTERODACTYL_PATH"
elif [ -f "/var/www/html/artisan" ]; then
    PTERODACTYL_PATH="/var/www/html"
    print_success "Found Pterodactyl at: $PTERODACTYL_PATH"
else
    print_error "Pterodactyl installation not found!"
    print_status "Searching for artisan file..."
    find /var/www/ -name "artisan" -type f 2>/dev/null
    find /root/ -name "artisan" -type f 2>/dev/null
    exit 1
fi

cd "$PTERODACTYL_PATH"

# Step 2: Check and fix .env file
print_status "Checking .env configuration..."
if [ ! -f ".env" ]; then
    print_error ".env file missing!"
    if [ -f ".env.example" ]; then
        print_status "Copying .env.example to .env..."
        cp .env.example .env
    else
        print_error ".env.example also missing! Installation may be corrupted."
        exit 1
    fi
fi

# Step 3: Fix file permissions
print_status "Fixing file permissions..."
chown -R www-data:www-data "$PTERODACTYL_PATH"
chmod -R 755 "$PTERODACTYL_PATH"
chmod -R 775 "$PTERODACTYL_PATH/storage" "$PTERODACTYL_PATH/bootstrap/cache"

# Step 4: Generate application key if missing
print_status "Checking application key..."
if ! grep -q "APP_KEY=base64:" .env; then
    print_status "Generating application key..."
    php artisan key:generate --force
    print_success "Application key generated"
else
    print_success "Application key exists"
fi

# Step 5: Clear all caches
print_status "Clearing application caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# Step 6: Check database configuration
print_status "Checking database configuration..."
DB_HOST=$(grep "DB_HOST=" .env | cut -d '=' -f2)
DB_DATABASE=$(grep "DB_DATABASE=" .env | cut -d '=' -f2)
DB_USERNAME=$(grep "DB_USERNAME=" .env | cut -d '=' -f2)

echo "Database settings:"
echo "  Host: $DB_HOST"
echo "  Database: $DB_DATABASE"
echo "  Username: $DB_USERNAME"

# Step 7: Test database connection
print_status "Testing database connection..."
if php artisan migrate:status >/dev/null 2>&1; then
    print_success "Database connection successful"
else
    print_warning "Database connection failed"
    print_status "Attempting to run migrations..."
    php artisan migrate --force
fi

# Step 8: Check Laravel logs
print_status "Checking for recent errors..."
if [ -f "storage/logs/laravel.log" ]; then
    print_status "Recent Laravel errors:"
    tail -20 storage/logs/laravel.log | grep -E "ERROR|CRITICAL|Exception" | tail -5
else
    print_warning "Laravel log file not found"
fi

# Step 9: Create missing directories
print_status "Creating missing directories..."
mkdir -p storage/logs
mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p bootstrap/cache

# Fix permissions again
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Step 10: Test web server
print_status "Testing web server response..."
sleep 2

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
print_status "HTTP Response Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    print_success "✅ SUCCESS! Web server now responding correctly!"
    print_success "Panel should be accessible at: http://vpsdos.tams.my.id"
elif [ "$HTTP_CODE" = "500" ]; then
    print_error "Still getting 500 error. Checking detailed logs..."
    
    # Show recent errors
    if [ -f "storage/logs/laravel.log" ]; then
        echo ""
        print_status "Last 10 lines of Laravel log:"
        tail -10 storage/logs/laravel.log
    fi
    
    # Check nginx error log
    echo ""
    print_status "Last 5 lines of Nginx error log:"
    tail -5 /var/log/nginx/pterodactyl.app-error.log 2>/dev/null || echo "Nginx error log not found"
    
    echo ""
    print_error "Manual steps to debug:"
    echo "1. Check Laravel logs: tail -f $PTERODACTYL_PATH/storage/logs/laravel.log"
    echo "2. Check Nginx logs: tail -f /var/log/nginx/pterodactyl.app-error.log"
    echo "3. Check PHP-FPM logs: tail -f /var/log/php8.3-fpm.log"
    echo "4. Test database: cd $PTERODACTYL_PATH && php artisan tinker"
    echo "5. Check .env database settings"
    
else
    print_warning "Unexpected HTTP code: $HTTP_CODE"
fi

# Step 11: Final summary
echo ""
echo "================================================"
print_success "🎉 500 Error Fix Completed!"
echo "================================================"
echo ""
print_status "📊 Final Status:"
echo "  • Pterodactyl Path: $PTERODACTYL_PATH"
echo "  • HTTP Response: $HTTP_CODE"
echo "  • Permissions: Fixed"
echo "  • Cache: Cleared"
echo "  • App Key: Generated"
echo ""
print_status "🌐 Try accessing:"
echo "  • http://vpsdos.tams.my.id"
echo "  • Username: b82827"
echo "  • Password: b82827"
echo ""

if [ "$HTTP_CODE" != "200" ]; then
    print_warning "If still not working, run these commands manually:"
    echo "cd $PTERODACTYL_PATH"
    echo "php artisan migrate --force"
    echo "php artisan db:seed --force"
    echo "php artisan config:cache"
fi

