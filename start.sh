#!/bin/bash

# Pterodactyl Panel Installer Bot v2.1 Enhanced
# Cross-Platform Linux/Unix Start Script
# Developer: NdikaFath ID

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions for colored output
print_header() {
    echo -e "${PURPLE}===============================================${NC}"
    echo -e "${PURPLE}  Pterodactyl Panel Installer Bot v2.1${NC}"
    echo -e "${PURPLE}  Enhanced Cross-Platform Support${NC}"
    echo -e "${PURPLE}  Developer: NdikaFath ID${NC}"
    echo -e "${PURPLE}===============================================${NC}"
}

print_info() {
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

# Get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check if we're running as root (optional warning)
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. This is not required for the bot."
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js tidak terdeteksi!"
        echo
        echo "Solusi:"
        echo "1. Install Node.js:"
        echo "   Ubuntu/Debian: sudo apt update && sudo apt install nodejs npm"
        echo "   CentOS/RHEL: sudo yum install nodejs npm"
        echo "   Or download from: https://nodejs.org/"
        echo "2. Restart terminal"
        echo "3. Jalankan script ini lagi"
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm tidak terdeteksi!"
        echo "Install npm package manager"
        exit 1
    fi
    
    print_success "Node.js $(node --version) detected"
    print_success "npm $(npm --version) detected"
}

# Check project files
check_project() {
    print_info "Checking project files..."
    
    if [ ! -f "package.json" ]; then
        print_error "package.json tidak ditemukan!"
        print_error "Pastikan Anda berada di direktori yang benar"
        exit 1
    fi
    
    if [ ! -f "bot.js" ]; then
        print_error "bot.js tidak ditemukan!"
        print_error "File bot utama hilang atau rusak"
        exit 1
    fi
    
    print_success "Project files found"
}

# Install dependencies
install_dependencies() {
    if [ ! -d "node_modules" ]; then
        print_info "node_modules tidak ditemukan, installing dependencies..."
        print_info "This may take 1-2 minutes..."
        
        npm install
        
        if [ $? -ne 0 ]; then
            print_error "Gagal install dependencies!"
            echo
            echo "Solusi:"
            echo "1. Pastikan koneksi internet stabil"
            echo "2. Coba: npm cache clean --force"
            echo "3. Hapus package-lock.json dan coba lagi"
            echo "4. Check permissions di direktori ini"
            exit 1
        fi
        
        print_success "Dependencies installed successfully!"
    else
        print_info "node_modules found, checking for updates..."
        npm outdated --silent 2>/dev/null || true
    fi
}

# Display system information
show_system_info() {
    echo
    print_header
    echo
    echo -e "${CYAN}SYSTEM INFORMATION:${NC}"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2 2>/dev/null || echo 'Unknown')"
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "Working Directory: $(pwd)"
    echo "User: $(whoami)"
    echo "Timestamp: $(get_timestamp)"
    echo
    echo -e "${CYAN}BOT CONFIGURATION:${NC}"
    echo "Bot File: bot.js"
    echo "Configuration: config.js"
    echo "Platform: Cross-platform Linux/Unix support"
    echo
    print_info "Starting Pterodactyl Panel Installer Bot..."
    print_info "Bot akan berjalan dengan enhanced error handling"
    print_info "Press Ctrl+C to stop the bot"
    print_info "Logs akan ditampilkan di terminal ini"
    echo
}

# Start bot with error handling and restart capability
start_bot() {
    local restart_count=0
    local max_restarts=3
    
    while true; do
        print_info "$(get_timestamp) - Attempting to start bot... (Attempt $((restart_count + 1)))"
        
        # Start the bot
        node bot.js
        local exit_code=$?
        
        # Check exit code
        if [ $exit_code -eq 0 ]; then
            print_info "Bot stopped normally"
            break
        else
            print_error "Bot exited with error code: $exit_code"
            echo
            echo "Possible issues:"
            echo "1. Network connectivity problems"
            echo "2. Invalid bot token"
            echo "3. Missing dependencies"
            echo "4. System resource constraints"
            echo "5. Permission issues"
            echo
            
            restart_count=$((restart_count + 1))
            
            if [ $restart_count -ge $max_restarts ]; then
                print_error "Maximum restart attempts ($max_restarts) reached"
                print_error "Please check the issues above and try again manually"
                break
            fi
            
            echo -n "Do you want to restart the bot? [Y/n]: "
            read -r response
            response=${response:-Y}
            
            if [[ $response =~ ^[Yy]$ ]]; then
                print_info "Restarting bot in 3 seconds..."
                sleep 3
                continue
            else
                print_info "User chose not to restart"
                break
            fi
        fi
    done
}

# Cleanup function
cleanup() {
    echo
    print_header
    echo
    print_info "Bot telah dihentikan"
    print_success "Terima kasih telah menggunakan bot ini!"
    echo
    echo "Untuk troubleshooting:"
    echo "1. Cek koneksi internet"
    echo "2. Verifikasi bot token di config.js"
    echo "3. Pastikan dependencies up to date: npm update"
    echo "4. Check system resources: free -h && df -h"
    echo "5. Hubungi developer jika masalah berlanjut"
    echo
}

# Handle signals
trap cleanup EXIT
trap 'echo; print_warning "Received interrupt signal"; exit 130' INT TERM

# Main execution
main() {
    clear
    print_header
    echo
    
    check_requirements
    check_project
    install_dependencies
    show_system_info
    start_bot
}

# Run main function
main "$@"
