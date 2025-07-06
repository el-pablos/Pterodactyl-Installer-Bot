#!/bin/bash

# Test Bot Configuration and Connectivity
# Pterodactyl Panel Installer Bot v2.1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} Bot Configuration Test v2.1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Test 1: Check Node.js and npm
test_nodejs() {
    print_test "Checking Node.js installation..."
    
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        local major_version=$(echo $node_version | cut -d. -f1 | sed 's/v//')
        
        if [ "$major_version" -ge 16 ]; then
            print_pass "Node.js $node_version (✓ >= v16)"
        else
            print_fail "Node.js $node_version (✗ < v16)"
            return 1
        fi
    else
        print_fail "Node.js not found"
        return 1
    fi
    
    if command -v npm &> /dev/null; then
        local npm_version=$(npm --version)
        print_pass "npm v$npm_version"
    else
        print_fail "npm not found"
        return 1
    fi
    
    return 0
}

# Test 2: Check project files
test_project_files() {
    print_test "Checking project files..."
    
    local required_files=("package.json" "bot.js" "config.js" "README.md")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_pass "$file exists"
        else
            print_fail "$file missing"
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        return 0
    else
        print_fail "Missing files: ${missing_files[*]}"
        return 1
    fi
}

# Test 3: Check dependencies
test_dependencies() {
    print_test "Checking dependencies..."
    
    if [ ! -d "node_modules" ]; then
        print_fail "node_modules directory not found"
        print_info "Run: npm install"
        return 1
    fi
    
    # Check critical dependencies
    local deps=("node-telegram-bot-api" "ssh2" "crypto")
    for dep in "${deps[@]}"; do
        if [ -d "node_modules/$dep" ]; then
            print_pass "$dep installed"
        else
            print_fail "$dep missing"
            return 1
        fi
    done
    
    return 0
}

# Test 4: Validate bot configuration
test_bot_config() {
    print_test "Validating bot configuration..."
    
    # Check if config.js exists and is readable
    if [ ! -r "config.js" ]; then
        print_fail "config.js not readable"
        return 1
    fi
    
    # Extract bot token and owner ID (basic validation)
    local bot_token=$(node -e "const config = require('./config.js'); console.log(config.BOT_TOKEN || 'missing');" 2>/dev/null)
    local owner_id=$(node -e "const config = require('./config.js'); console.log(config.OWNER_ID || 'missing');" 2>/dev/null)
    
    if [ "$bot_token" = "missing" ] || [ ${#bot_token} -lt 40 ]; then
        print_fail "Invalid or missing BOT_TOKEN"
        return 1
    else
        print_pass "BOT_TOKEN configured (${bot_token:0:10}...)"
    fi
    
    if [ "$owner_id" = "missing" ] || [ "$owner_id" -eq 0 ] 2>/dev/null; then
        print_fail "Invalid or missing OWNER_ID"
        return 1
    else
        print_pass "OWNER_ID configured ($owner_id)"
    fi
    
    return 0
}

# Test 5: Test bot syntax
test_bot_syntax() {
    print_test "Testing bot syntax..."
    
    local syntax_check=$(node -c bot.js 2>&1)
    if [ $? -eq 0 ]; then
        print_pass "Bot syntax is valid"
        return 0
    else
        print_fail "Bot syntax error:"
        echo "$syntax_check"
        return 1
    fi
}

# Test 6: Test network connectivity
test_network() {
    print_test "Testing network connectivity..."
    
    # Test internet connection
    if ping -c 1 google.com &> /dev/null; then
        print_pass "Internet connectivity OK"
    else
        print_fail "No internet connection"
        return 1
    fi
    
    # Test Telegram API connectivity
    if curl -s "https://api.telegram.org" &> /dev/null; then
        print_pass "Telegram API accessible"
    else
        print_fail "Cannot reach Telegram API"
        return 1
    fi
    
    return 0
}

# Test 7: Test bot startup (quick test)
test_bot_startup() {
    print_test "Testing bot startup (10 second test)..."
    
    # Start bot in background and test for 10 seconds
    timeout 10s node bot.js &> /tmp/bot_test.log &
    local bot_pid=$!
    
    sleep 3
    
    # Check if bot is still running
    if kill -0 $bot_pid 2>/dev/null; then
        print_pass "Bot started successfully"
        kill $bot_pid 2>/dev/null
        return 0
    else
        print_fail "Bot failed to start"
        print_info "Error log:"
        cat /tmp/bot_test.log | tail -5
        return 1
    fi
}

# Test 8: Test bot token validity
test_bot_token() {
    print_test "Testing bot token validity..."
    
    local bot_token=$(node -e "const config = require('./config.js'); console.log(config.BOT_TOKEN);" 2>/dev/null)
    
    if [ -z "$bot_token" ]; then
        print_fail "Bot token not found"
        return 1
    fi
    
    # Test bot token with Telegram API
    local response=$(curl -s "https://api.telegram.org/bot$bot_token/getMe")
    
    if echo "$response" | grep -q '"ok":true'; then
        local bot_username=$(echo "$response" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
        print_pass "Bot token valid (Username: @$bot_username)"
        return 0
    else
        print_fail "Invalid bot token"
        print_info "Response: $response"
        return 1
    fi
}

# Main test runner
run_all_tests() {
    print_header
    echo
    
    local tests=(
        "test_nodejs"
        "test_project_files" 
        "test_dependencies"
        "test_bot_config"
        "test_bot_syntax"
        "test_network"
        "test_bot_token"
        "test_bot_startup"
    )
    
    local passed=0
    local failed=0
    local total=${#tests[@]}
    
    for test in "${tests[@]}"; do
        echo
        if $test; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} Test Results Summary${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "Total Tests: $total"
    echo -e "${GREEN}Passed: $passed${NC}"
    echo -e "${RED}Failed: $failed${NC}"
    
    if [ $failed -eq 0 ]; then
        echo
        print_pass "All tests passed! Bot is ready to use."
        echo
        echo "Next steps:"
        echo "1. Start the bot: npm start (or ./start.sh)"
        echo "2. Test with: /help command in Telegram"
        echo "3. Try installation: /installpanel ip|pass|domain|node|ram"
        return 0
    else
        echo
        print_fail "Some tests failed. Please fix the issues above."
        echo
        echo "Common solutions:"
        echo "1. Install dependencies: npm install"
        echo "2. Check bot token in config.js"
        echo "3. Verify internet connection"
        echo "4. Update Node.js if version < 16"
        return 1
    fi
}

# Run individual test if specified
if [ $# -eq 1 ]; then
    case $1 in
        "nodejs") test_nodejs ;;
        "files") test_project_files ;;
        "deps") test_dependencies ;;
        "config") test_bot_config ;;
        "syntax") test_bot_syntax ;;
        "network") test_network ;;
        "token") test_bot_token ;;
        "startup") test_bot_startup ;;
        *)
            echo "Usage: $0 [nodejs|files|deps|config|syntax|network|token|startup]"
            echo "Or run without arguments for all tests"
            exit 1
            ;;
    esac
else
    run_all_tests
fi
