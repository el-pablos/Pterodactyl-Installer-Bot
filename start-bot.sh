#!/bin/bash

# 🚀 Enhanced Bot Startup Script
# Handles network issues and auto-restart

echo "🚀 Starting Pterodactyl Panel Installer Bot..."
echo "=============================================="

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

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed!"
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
fi

# Check if npm packages are installed
if [ ! -d "node_modules" ]; then
    print_status "Installing npm packages..."
    npm install
fi

# Function to test internet connectivity
test_connectivity() {
    print_status "Testing internet connectivity..."
    
    # Test general connectivity
    if ping -c 1 -W 3 google.com >/dev/null 2>&1; then
        print_success "Internet connectivity: OK"
    else
        print_warning "Internet connectivity: FAILED"
        return 1
    fi
    
    # Test Telegram API connectivity
    if curl -s --connect-timeout 5 https://api.telegram.org >/dev/null; then
        print_success "Telegram API connectivity: OK"
        return 0
    else
        print_warning "Telegram API connectivity: FAILED"
        return 1
    fi
}

# Function to start bot with retry
start_bot() {
    local attempt=1
    local max_attempts=3
    
    while [ $attempt -le $max_attempts ]; do
        print_status "Starting bot (attempt $attempt/$max_attempts)..."
        
        # Test connectivity first
        if test_connectivity; then
            print_status "Starting Node.js bot..."
            
            # Start bot with timeout
            timeout 10s node bot.js &
            BOT_PID=$!
            
            # Wait a bit to see if bot starts successfully
            sleep 5
            
            if kill -0 $BOT_PID 2>/dev/null; then
                print_success "Bot started successfully (PID: $BOT_PID)"
                
                # Wait for bot to finish or fail
                wait $BOT_PID
                BOT_EXIT_CODE=$?
                
                if [ $BOT_EXIT_CODE -eq 0 ]; then
                    print_success "Bot exited normally"
                    break
                else
                    print_warning "Bot exited with code: $BOT_EXIT_CODE"
                fi
            else
                print_error "Bot failed to start"
            fi
        else
            print_error "Network connectivity issues detected"
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            print_status "Waiting 10 seconds before retry..."
            sleep 10
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "Failed to start bot after $max_attempts attempts"
        return 1
    fi
}

# Function to run bot with auto-restart
run_with_restart() {
    local restart_count=0
    local max_restarts=5
    
    while [ $restart_count -lt $max_restarts ]; do
        print_status "Bot run #$((restart_count + 1))"
        
        if start_bot; then
            print_success "Bot completed successfully"
            break
        else
            restart_count=$((restart_count + 1))
            
            if [ $restart_count -lt $max_restarts ]; then
                print_warning "Bot failed, restarting in 15 seconds... ($restart_count/$max_restarts)"
                sleep 15
            else
                print_error "Bot failed after $max_restarts attempts"
                break
            fi
        fi
    done
}

# Main execution
print_status "Checking system requirements..."

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null || echo "not installed")
print_status "Node.js version: $NODE_VERSION"

# Check npm version
NPM_VERSION=$(npm --version 2>/dev/null || echo "not installed")
print_status "npm version: $NPM_VERSION"

# Check if bot.js exists
if [ ! -f "bot.js" ]; then
    print_error "bot.js not found in current directory!"
    print_status "Current directory: $(pwd)"
    print_status "Files in directory:"
    ls -la
    exit 1
fi

print_success "All requirements met"

# Check for command line arguments
if [ "$1" = "--no-restart" ]; then
    print_status "Running bot without auto-restart..."
    start_bot
elif [ "$1" = "--test" ]; then
    print_status "Testing connectivity only..."
    test_connectivity
elif [ "$1" = "--simple" ]; then
    print_status "Running bot in simple mode..."
    node bot.js
else
    print_status "Running bot with auto-restart..."
    run_with_restart
fi

print_status "Bot startup script completed"
