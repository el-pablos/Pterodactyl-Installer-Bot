#!/bin/bash

# Enhanced Pterodactyl Panel Troubleshooting Script v2.1
# Auto-fix common issues for failed installations with APT lock resolution

echo "🔧 Enhanced Pterodactyl Panel Troubleshooting Script v2.1"
echo "==========================================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check OS compatibility with enhanced detection
check_os() {
    print_status "Checking OS compatibility..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_ID=$ID
    else
        OS_VERSION=$(lsb_release -rs 2>/dev/null || echo "Unknown")
        OS_NAME=$(lsb_release -ds 2>/dev/null || echo "Unknown Linux")
        OS_ID=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "unknown")
    fi
    
    echo "Detected: $OS_NAME ($OS_VERSION)"
    
    case $OS_ID in
        ubuntu)
            case $OS_VERSION in
                "20.04"|"22.04")
                    print_success "Ubuntu $OS_VERSION is supported!"
                    return 0
                    ;;
                "24.04"|"24.10")
                    print_error "Ubuntu $OS_VERSION is NOT supported!"
                    print_warning "Pterodactyl installer does not support Ubuntu 24.x"
                    echo "Supported versions: Ubuntu 20.04 LTS, 22.04 LTS"
                    echo "Download: https://ubuntu.com/download/server"
                    return 1
                    ;;
                *)
                    print_warning "Ubuntu $OS_VERSION not officially tested"
                    echo "Recommended: Ubuntu 20.04 or 22.04 LTS"
                    return 2
                    ;;
            esac
            ;;
        debian)
            if [[ "$OS_VERSION" =~ ^(10|11|12)$ ]]; then
                print_success "Debian $OS_VERSION is supported!"
                return 0
            else
                print_warning "Debian $OS_VERSION may not be fully supported"
                return 2
            fi
            ;;
        *)
            print_error "Operating system '$OS_ID' is not supported"
            print_warning "This script is designed for Ubuntu 20.04/22.04 LTS"
            return 1
            ;;
    esac
}

# Enhanced APT lock and repository fixes
fix_repositories() {
    print_status "Fixing APT locks and repository issues..."
    
    # Step 1: Kill hanging APT processes
    print_step "Terminating hanging APT processes..."
    local processes=("apt-get" "apt" "dpkg" "unattended-upgrade" "packagekit" "snapd")
    for process in "${processes[@]}"; do
        if pgrep -f "$process" > /dev/null; then
            print_warning "Killing $process processes..."
            pkill -f "$process" || true
        fi
    done
    
    # Wait for processes to stop
    print_status "Waiting for processes to stop..."
    sleep 5
    
    # Step 2: Remove lock files
    print_step "Removing APT lock files..."
    local lock_files=(
        "/var/lib/dpkg/lock-frontend"
        "/var/lib/dpkg/lock"
        "/var/cache/apt/archives/lock"
        "/var/lib/apt/lists/lock"
        "/var/log/unattended-upgrades/unattended-upgrades-dpkg.log"
    )
    
    for lock_file in "${lock_files[@]}"; do
        if [ -f "$lock_file" ]; then
            rm -f "$lock_file" && print_status "Removed: $lock_file"
        fi
    done
    
    # Step 3: Fix broken packages
    print_step "Fixing broken packages..."
    dpkg --configure -a 2>/dev/null || {
        print_warning "Some packages may still be broken"
    }
    
    # Step 4: Remove problematic PPAs for Ubuntu 24.x
    if [[ "$OS_VERSION" =~ ^24\. ]]; then
        print_step "Removing problematic PPAs for Ubuntu 24.x..."
        find /etc/apt/sources.list.d/ -name "*ondrej*" -delete 2>/dev/null || true
        find /etc/apt/sources.list.d/ -name "*php*" -delete 2>/dev/null || true
        print_success "Problematic PPAs removed"
    fi
    
    # Step 5: Clean and update
    print_step "Cleaning APT cache..."
    apt-get clean || true
    apt-get autoclean || true
    
    print_step "Updating package lists..."
    local update_attempts=0
    local max_attempts=3
    
    while [ $update_attempts -lt $max_attempts ]; do
        if apt-get update 2>/dev/null; then
            print_success "Package lists updated successfully"
            break
        else
            update_attempts=$((update_attempts + 1))
            print_warning "Update attempt $update_attempts failed, retrying in 5 seconds..."
            sleep 5
        fi
    done
    
    if [ $update_attempts -eq $max_attempts ]; then
        print_error "Failed to update package lists after $max_attempts attempts"
        return 1
    fi
    
    # Step 6: Fix broken packages again
    print_step "Final package fix..."
    apt-get --fix-broken install -y 2>/dev/null || true
    
    print_success "APT locks and repository issues fixed!"
    return 0
}

# Enhanced permission fixes
fix_permissions() {
    print_status "Checking and fixing Pterodactyl permissions..."
    
    local fixed_issues=0
    
    if [ -d "/var/www/pterodactyl" ]; then
        print_step "Fixing Pterodactyl panel permissions..."
        
        # Set ownership
        chown -R www-data:www-data /var/www/pterodactyl/ 2>/dev/null && {
            print_success "Panel ownership fixed"
            fixed_issues=$((fixed_issues + 1))
        }
        
        # Set directory permissions
        find /var/www/pterodactyl -type d -exec chmod 755 {} \; 2>/dev/null && {
            print_success "Directory permissions fixed"
            fixed_issues=$((fixed_issues + 1))
        }
        
        # Set file permissions
        find /var/www/pterodactyl -type f -exec chmod 644 {} \; 2>/dev/null && {
            print_success "File permissions fixed"
            fixed_issues=$((fixed_issues + 1))
        }
        
        # Special permissions for storage and cache
        if [ -d "/var/www/pterodactyl/storage" ]; then
            chmod -R 755 /var/www/pterodactyl/storage 2>/dev/null
            print_success "Storage permissions fixed"
            fixed_issues=$((fixed_issues + 1))
        fi
        
        if [ -d "/var/www/pterodactyl/bootstrap/cache" ]; then
            chmod -R 755 /var/www/pterodactyl/bootstrap/cache 2>/dev/null
            print_success "Cache permissions fixed"
            fixed_issues=$((fixed_issues + 1))
        fi
        
        # Make artisan executable
        if [ -f "/var/www/pterodactyl/artisan" ]; then
            chmod +x /var/www/pterodactyl/artisan 2>/dev/null
            print_success "Artisan executable permissions set"
            fixed_issues=$((fixed_issues + 1))
        fi
        
    else
        print_warning "Pterodactyl directory not found. Panel might not be installed."
        return 1
    fi
    
    # Fix Wings permissions
    if [ -d "/etc/pterodactyl" ]; then
        print_step "Fixing Wings permissions..."
        chown -R root:root /etc/pterodactyl/ 2>/dev/null
        chmod -R 600 /etc/pterodactyl/ 2>/dev/null
        print_success "Wings permissions fixed"
        fixed_issues=$((fixed_issues + 1))
    fi
    
    print_success "Fixed $fixed_issues permission issues!"
    return 0
}

# Enhanced service status check
check_services() {
    print_status "Checking services status..."
    
    local services=("nginx" "mysql" "mariadb" "redis-server" "pterodactyl-queue-worker" "wings")
    local running_services=0
    local total_services=0
    local failed_services=()
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service"; then
            total_services=$((total_services + 1))
            
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                print_success "$service is running"
                running_services=$((running_services + 1))
            else
                print_error "$service is not running"
                failed_services+=("$service")
                
                # Try to start the service
                print_status "Attempting to start $service..."
                if systemctl start "$service" 2>/dev/null; then
                    systemctl enable "$service" 2>/dev/null
                    
                    # Check if it started successfully
                    sleep 2
                    if systemctl is-active --quiet "$service"; then
                        print_success "$service started successfully"
                        running_services=$((running_services + 1))
                        # Remove from failed services
                        failed_services=("${failed_services[@]/$service}")
                    else
                        print_error "Failed to start $service"
                        # Show error details
                        echo "Error details:"
                        systemctl status "$service" --no-pager -l | tail -5
                    fi
                else
                    print_error "Failed to start $service"
                fi
            fi
        fi
    done
    
    echo
    print_status "Service Summary:"
    echo "Running: $running_services/$total_services"
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        echo "Failed services: ${failed_services[*]}"
        return 1
    else
        print_success "All services are running!"
        return 0
    fi
}

# Check SSL certificates with enhanced details
check_ssl() {
    print_status "Checking SSL certificates..."
    
    if command -v certbot &> /dev/null; then
        local cert_info
        cert_info=$(certbot certificates 2>/dev/null)
        
        if [ -n "$cert_info" ] && echo "$cert_info" | grep -q "Certificate Name:"; then
            echo "$cert_info"
            print_success "SSL certificates found"
            
            # Check expiration
            echo "$cert_info" | grep -A 5 "Certificate Name:" | while read -r line; do
                if echo "$line" | grep -q "Expiry Date:"; then
                    expiry_date=$(echo "$line" | sed 's/.*Expiry Date: //' | cut -d' ' -f1-2)
                    echo "Certificate expires: $expiry_date"
                fi
            done
            
            return 0
        else
            print_warning "No SSL certificates found"
            print_status "You may need to run SSL installation manually"
            echo "Command: certbot --nginx -d your-domain.com"
            return 1
        fi
    else
        print_warning "Certbot not installed"
        print_status "Install with: apt install certbot python3-certbot-nginx"
        return 1
    fi
}

# Enhanced disk space check
check_disk_space() {
    print_status "Checking disk space..."
    
    echo "Disk Usage Summary:"
    df -h / /tmp /var 2>/dev/null | grep -E '^/|tmpfs'
    echo
    
    # Check root partition
    local usage
    usage=$(df / | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 }' | cut -d'%' -f1)
    
    if [ "$usage" -gt 95 ]; then
        print_error "Critical: Root partition is ${usage}% full!"
        print_warning "Immediate cleanup required"
        return 2
    elif [ "$usage" -gt 90 ]; then
        print_warning "Warning: Root partition is ${usage}% full"
        print_status "Consider cleaning up disk space"
        return 1
    else
        print_success "Disk space is sufficient (${usage}% used)"
    fi
    
    # Check /tmp partition
    if mountpoint -q /tmp; then
        local tmp_usage
        tmp_usage=$(df /tmp | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 }' | cut -d'%' -f1)
        if [ "$tmp_usage" -gt 90 ]; then
            print_warning "/tmp partition is ${tmp_usage}% full"
        fi
    fi
    
    # Check /var partition
    if mountpoint -q /var; then
        local var_usage
        var_usage=$(df /var | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 }' | cut -d'%' -f1)
        if [ "$var_usage" -gt 90 ]; then
            print_warning "/var partition is ${var_usage}% full"
        fi
    fi
    
    # Show disk cleanup suggestions if needed
    if [ "$usage" -gt 80 ]; then
        echo
        print_status "Disk cleanup suggestions:"
        echo "1. Clean package cache: apt-get clean"
        echo "2. Remove old kernels: apt autoremove"
        echo "3. Clean logs: journalctl --vacuum-time=7d"
        echo "4. Clean temporary files: rm -rf /tmp/*"
    fi
    
    return 0
}

# Enhanced network connectivity check
check_network() {
    print_status "Checking network connectivity..."
    
    local tests_passed=0
    local total_tests=5
    
    # Test 1: Internet connection
    if ping -c 1 -W 3 google.com &> /dev/null; then
        print_success "Internet connectivity: OK"
        tests_passed=$((tests_passed + 1))
    else
        print_error "Internet connectivity: FAILED"
        print_warning "Cannot reach external servers"
    fi
    
    # Test 2: DNS resolution
    if nslookup google.com &> /dev/null; then
        print_success "DNS resolution: OK"
        tests_passed=$((tests_passed + 1))
    else
        print_error "DNS resolution: FAILED"
        print_warning "DNS servers may be unreachable"
    fi
    
    # Test 3: Package repositories
    if timeout 10 apt-get update -qq 2>/dev/null; then
        print_success "Package repositories: OK"
        tests_passed=$((tests_passed + 1))
    else
        print_error "Package repositories: FAILED"
        print_warning "Cannot reach package repositories"
    fi
    
    # Test 4: HTTPS connectivity
    if curl -s --connect-timeout 5 https://github.com &> /dev/null; then
        print_success "HTTPS connectivity: OK"
        tests_passed=$((tests_passed + 1))
    else
        print_error "HTTPS connectivity: FAILED"
        print_warning "SSL/TLS connections may be blocked"
    fi
    
    # Test 5: Check open ports
    print_status "Checking open ports..."
    local required_ports=(80 443 22)
    local open_ports=0
    
    for port in "${required_ports[@]}"; do
        if ss -tuln | grep -q ":$port "; then
            echo "  ✓ Port $port is open"
            open_ports=$((open_ports + 1))
        else
            echo "  ✗ Port $port is closed"
        fi
    done
    
    if [ $open_ports -eq ${#required_ports[@]} ]; then
        print_success "All required ports are open"
        tests_passed=$((tests_passed + 1))
    else
        print_warning "Some required ports are not open"
    fi
    
    echo
    print_status "Network tests: $tests_passed/$total_tests passed"
    
    if [ $tests_passed -eq $total_tests ]; then
        return 0
    elif [ $tests_passed -ge 3 ]; then
        return 1
    else
        return 2
    fi
}

# Enhanced system resource check
check_system_resources() {
    print_status "Checking system resources..."
    
    echo "System Information:"
    echo "  OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo
    
    # Memory check
    local mem_info
    mem_info=$(free -h | grep Mem)
    echo "Memory: $mem_info"
    
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    
    if [ "$mem_usage" -gt 90 ]; then
        print_error "High memory usage: ${mem_usage}%"
    elif [ "$mem_usage" -gt 75 ]; then
        print_warning "Moderate memory usage: ${mem_usage}%"
    else
        print_success "Memory usage is normal: ${mem_usage}%"
    fi
    
    # CPU load check
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores
    cpu_cores=$(nproc)
    
    echo "Load Average: $load_avg (CPU cores: $cpu_cores)"
    
    # Check for swap usage
    local swap_info
    swap_info=$(free -h | grep Swap)
    if echo "$swap_info" | grep -qv "0B.*0B"; then
        echo "Swap: $swap_info"
        local swap_usage
        swap_usage=$(free | grep Swap | awk '{if($2>0) printf "%.0f", $3/$2 * 100.0; else print "0"}')
        if [ "$swap_usage" -gt 50 ]; then
            print_warning "High swap usage: ${swap_usage}%"
        fi
    else
        echo "Swap: Not configured or not in use"
    fi
    
    return 0
}

# Clean installation with enhanced cleanup
clean_install() {
    print_warning "This will remove existing Pterodactyl installation!"
    echo "The following will be removed:"
    echo "  - Pterodactyl Panel (/var/www/pterodactyl)"
    echo "  - Wings configuration (/etc/pterodactyl)"
    echo "  - Service files"
    echo "  - Database and users (optional)"
    echo
    read -p "Are you sure? Type 'yes' to confirm: " -r
    
    if [ "$REPLY" != "yes" ]; then
        print_status "Clean installation cancelled"
        return 0
    fi
    
    print_status "Starting clean installation process..."
    
    # Stop services
    print_step "Stopping services..."
    local services_to_stop=("nginx" "pterodactyl-queue-worker" "wings")
    for service in "${services_to_stop[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            systemctl stop "$service" 2>/dev/null && print_status "Stopped $service"
        fi
    done
    
    # Remove directories
    print_step "Removing directories..."
    rm -rf /var/www/pterodactyl && print_status "Removed panel directory"
    rm -rf /etc/pterodactyl && print_status "Removed wings directory"
    
    # Remove service files
    print_step "Removing service files..."
    rm -f /etc/systemd/system/pterodactyl-queue-worker.service
    rm -f /etc/systemd/system/wings.service
    systemctl daemon-reload
    
    # Optional database cleanup
    echo
    read -p "Do you want to remove databases and users? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Cleaning up databases..."
        mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
        mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'%';" 2>/dev/null || true
        mysql -u root -e "DROP USER IF EXISTS 'pterodactyluser'@'%';" 2>/dev/null || true
        mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
        print_status "Database cleanup completed"
    fi
    
    # Remove SSL certificates
    read -p "Do you want to remove SSL certificates? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Removing SSL certificates..."
        if command -v certbot &> /dev/null; then
            certbot delete --cert-name panel.example.com 2>/dev/null || true
            print_status "SSL certificates removed"
        fi
    fi
    
    print_success "Clean installation completed!"
    print_status "System is ready for fresh Pterodactyl installation"
}

# Comprehensive system diagnostic
run_full_diagnostic() {
    print_status "Running comprehensive system diagnostic..."
    echo
    
    local total_checks=0
    local passed_checks=0
    local warning_checks=0
    local failed_checks=0
    
    # Array of diagnostic functions
    local diagnostics=(
        "check_os"
        "check_system_resources"
        "check_disk_space" 
        "check_network"
        "fix_repositories"
        "check_services"
        "fix_permissions"
        "check_ssl"
    )
    
    for diagnostic in "${diagnostics[@]}"; do
        echo
        print_step "Running: $diagnostic"
        total_checks=$((total_checks + 1))
        
        if $diagnostic; then
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                passed_checks=$((passed_checks + 1))
            elif [ $exit_code -eq 1 ]; then
                warning_checks=$((warning_checks + 1))
            else
                failed_checks=$((failed_checks + 1))
            fi
        else
            failed_checks=$((failed_checks + 1))
        fi
    done
    
    # Summary
    echo
    echo "========================================"
    print_status "DIAGNOSTIC SUMMARY"
    echo "========================================"
    echo "Total Checks: $total_checks"
    echo -e "${GREEN}Passed: $passed_checks${NC}"
    echo -e "${YELLOW}Warnings: $warning_checks${NC}"
    echo -e "${RED}Failed: $failed_checks${NC}"
    echo
    
    if [ $failed_checks -eq 0 ] && [ $warning_checks -eq 0 ]; then
        print_success "All diagnostics passed! System is ready for Pterodactyl installation."
    elif [ $failed_checks -eq 0 ]; then
        print_warning "Some warnings detected, but system should work."
    else
        print_error "Critical issues detected. Please fix before proceeding."
    fi
    
    return $failed_checks
}

# Enhanced main menu
show_menu() {
    echo
    echo "🔧 Select troubleshooting option:"
    echo "=========================================="
    echo "1.  Check OS compatibility"
    echo "2.  Fix APT locks & repositories (Enhanced)"
    echo "3.  Fix permissions"
    echo "4.  Check services status"
    echo "5.  Check SSL certificates"
    echo "6.  Check disk space"
    echo "7.  Check network connectivity"
    echo "8.  Check system resources"
    echo "9.  Run all checks (Comprehensive)"
    echo "10. Clean installation (DANGEROUS)"
    echo "11. Full system diagnostic"
    echo "12. Generate system report"
    echo "0.  Exit"
    echo "=========================================="
}

# Generate system report
generate_system_report() {
    local report_file="pterodactyl_system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    print_status "Generating system report..."
    
    {
        echo "Pterodactyl System Report"
        echo "========================"
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo
        
        echo "System Information:"
        echo "==================="
        uname -a
        echo
        lsb_release -a 2>/dev/null || cat /etc/os-release
        echo
        
        echo "Hardware Information:"
        echo "===================="
        echo "CPU: $(nproc) cores"
        cat /proc/cpuinfo | grep "model name" | head -1
        echo
        free -h
        echo
        df -h
        echo
        
        echo "Network Configuration:"
        echo "====================="
        ip addr show
        echo
        cat /etc/resolv.conf
        echo
        
        echo "Service Status:"
        echo "==============="
        systemctl status nginx mysql redis-server pterodactyl-queue-worker wings --no-pager 2>/dev/null || echo "Some services not found"
        echo
        
        echo "Process List:"
        echo "============="
        ps aux | head -20
        echo
        
        echo "Network Connections:"
        echo "==================="
        ss -tuln | head -20
        echo
        
        echo "Recent Logs:"
        echo "============"
        journalctl --no-pager -n 20 2>/dev/null || echo "Cannot access journal"
        
    } > "$report_file"
    
    print_success "System report generated: $report_file"
    print_status "You can share this report for technical support"
}

# Main script
main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Enter your choice (0-12): " choice
        
        case $choice in
            1) check_os ;;
            2) fix_repositories ;;
            3) fix_permissions ;;
            4) check_services ;;
            5) check_ssl ;;
            6) check_disk_space ;;
            7) check_network ;;
            8) check_system_resources ;;
            9) 
                check_os
                fix_repositories
                fix_permissions
                check_services
                check_ssl
                check_disk_space
                check_network
                check_system_resources
                print_success "All checks completed!"
                ;;
            10) clean_install ;;
            11) run_full_diagnostic ;;
            12) generate_system_report ;;
            0) 
                print_status "Exiting troubleshooting script"
                exit 0
                ;;
            *) 
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Run main function
main
