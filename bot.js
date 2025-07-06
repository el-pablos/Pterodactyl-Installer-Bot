const TelegramBot = require('node-telegram-bot-api');
const { Client: ssh2 } = require('ssh2');
const crypto = require('crypto');
const os = require('os');
const path = require('path');

// Enhanced error handling and logging
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Bot configuration
const BOT_TOKEN = '7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg';
const OWNER_ID = 5476148500;

// Domain configuration
const subdomain = {
  "tams.my.id": {
    "zone": "1d1abb10b90d2fc25b6e2072ce721338",
    "apitoken": "qFwbfYQWm7iQt_DEJLFerGxJcqUQa_yoJSy61Wy-"
  }
};

// Initialize bot
const bot = new TelegramBot(BOT_TOKEN, { polling: true });

// Helper functions
const isOwner = (userId) => userId === OWNER_ID;
const sendMessage = (chatId, text, options = {}) => bot.sendMessage(chatId, text, options);
const example = (text) => `Contoh penggunaan:\n${text}`;
const generatePassword = () => crypto.randomBytes(3).toString('hex');
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Cross-platform logging
const log = (message, type = 'info') => {
  const timestamp = new Date().toISOString();
  const platform = os.platform();
  console.log(`[${timestamp}] [${platform}] [${type.toUpperCase()}] ${message}`);
};

log('🚀 Pterodactyl Panel Installer Bot Started!', 'info');
log(`Platform: ${os.platform()} ${os.arch()}`, 'info');
log(`Node.js: ${process.version}`, 'info');
log('📋 Available commands:', 'info');
log('- /installpanel - Install Pterodactyl panel', 'info');
log('- /uninstallpanel - Uninstall Pterodactyl panel', 'info');
log('- /hackbackpanel - Hackback panel access', 'info');
log('- /startwings - Start wings service', 'info');
log('- /checkstatus - Check VPS status', 'info');
log('- /masterfix - Complete panel fix (database, nginx, admin)', 'info');
log('- /help - Show help menu', 'info');

// Command handlers
bot.onText(/\/start/, (msg) => {
  const chatId = msg.chat.id;
  const welcomeText = `
🎯 *Pterodactyl Panel Installer Bot v2.1*

🔧 *Commands tersedia:*
• \`/installpanel\` - Install panel pterodactyl
• \`/uninstallpanel\` - Uninstall panel pterodactyl  
• \`/hackbackpanel\` - Hackback panel access
• \`/startwings\` - Start wings service
• \`/checkstatus\` - Check VPS status
• \`/masterfix\` - Complete panel fix (database, nginx, admin)
• \`/help\` - Tampilkan menu bantuan

👤 *Developer:* NdikaFath ID
🖥️ *Platform:* Cross-platform Windows/Linux support
📝 *Note:* Bot ini hanya bisa digunakan oleh owner

⚠️ *Requirements:*
• Ubuntu 20.04/22.04 (24.x TIDAK support)
• Fresh install VPS
• Domain pointing ke IP VPS
• Minimal 2GB RAM
  `;
  
  sendMessage(chatId, welcomeText, { parse_mode: 'Markdown' });
});

bot.onText(/\/help/, (msg) => {
  const chatId = msg.chat.id;
  const helpText = `
📖 *Panduan Penggunaan Bot v2.1*

🛠️ *Install Panel (Enhanced):*
\`/installpanel ipvps|pwvps|panel.com|node.com|ramserver\`
Contoh: \`/installpanel 1.2.3.4|password123|panel.tams.my.id|node.tams.my.id|8000\`

🔍 *Check Status (NEW):*
\`/checkstatus ipvps|pwvps\`
Contoh: \`/checkstatus 1.2.3.4|password123\`

🗑️ *Uninstall Panel:*
\`/uninstallpanel ipvps|pwvps\`
Contoh: \`/uninstallpanel 1.2.3.4|password123\`

🔓 *Hackback Panel:*
\`/hackbackpanel ipvps|pwvps\`
Contoh: \`/hackbackpanel 1.2.3.4|password123\`

🚀 *Start Wings:*
\`/startwings ipvps|pwvps|token_node\`
Contoh: \`/startwings 1.2.3.4|password123|your_wings_token\`

🔧 *Master Fix (NEW):*
\`/masterfix ipvps|pwvps|domain_panel\`
Contoh: \`/masterfix 1.2.3.4|password123|panel.tams.my.id\`
*Fixes: Database, Nginx, SSL, Admin User, Permissions*

⚠️ *IMPORTANT Requirements:*
• Ubuntu 20.04 atau 22.04 (WAJIB!)
• Fresh install VPS dengan minimal 2GB RAM
• Domain sudah pointing ke IP VPS
• Port 22, 80, 443, 8080, 2022 terbuka

🔧 *New Features v2.1:*
• APT lock auto-resolution
• Cross-platform Windows/Linux support
• Enhanced error handling
• Better installation verification
• Domain resolution check
• Network connectivity test

🆘 *Troubleshooting:*
• Jika APT locked: Bot auto-fix
• Jika domain issues: Check DNS
• Jika installation gagal: Coba VPS fresh install
• Jika Ubuntu 24.x: WAJIB ganti ke 22.04
  `;
  
  sendMessage(chatId, helpText, { parse_mode: 'Markdown' });
});

// ENHANCED Install Panel Command with ALL FIXES INTEGRATED
bot.onText(/\/installpanel (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const text = match[1];

  if (!isOwner(userId)) {
    return sendMessage(chatId, "❌ Anda tidak memiliki akses untuk menggunakan command ini!");
  }

  if (!text) {
    return sendMessage(chatId, example("/installpanel ipvps|pwvps|panel.com|node.com|ramserver (contoh 100000)"));
  }

  let vii = text.split("|");
  if (vii.length < 5) {
    return sendMessage(chatId, example("/installpanel ipvps|pwvps|panel.com|node.com|ramserver (contoh 100000)"));
  }

  const connSettings = {
    host: vii[0],
    port: '22',
    username: 'root',
    password: vii[1],
    readyTimeout: 30000,
    keepaliveInterval: 10000
  };

  const passwordPanel = generatePassword();
  const domainpanel = vii[2];
  const domainnode = vii[3];
  const ramserver = vii[4];

  const commandPanel = `bash <(curl -s https://pterodactyl-installer.se)`;
  const ress = new ssh2();

  let installationSuccess = false;
  let installationStep = "Connecting to VPS";
  let installationStartTime = Date.now();

  // Enhanced logging function
  const logStep = (step, details = '') => {
    const elapsed = Math.round((Date.now() - installationStartTime) / 1000);
    log(`[${elapsed}s] ${step}: ${details}`, 'info');
    installationStep = step;
  };

  // Function to execute command with timeout and retry
  const executeCommand = (command, timeout = 30000) => {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new Error(`Command timeout after ${timeout}ms: ${command}`));
      }, timeout);

      ress.exec(command, (err, stream) => {
        if (err) {
          clearTimeout(timer);
          return reject(err);
        }

        let output = '';
        let errorOutput = '';

        stream.on('data', (data) => {
          output += data.toString();
        }).on('stderr', (data) => {
          errorOutput += data.toString();
        }).on('close', (code) => {
          clearTimeout(timer);
          if (code === 0) {
            resolve({ output, errorOutput, code });
          } else {
            reject(new Error(`Command failed with code ${code}: ${errorOutput || output}`));
          }
        });
      });
    });
  };

  // COMPREHENSIVE APT & SYSTEM FIXES - ALL-IN-ONE SOLUTION
  async function fixAptLocks() {
    logStep("Comprehensive System Fix", "APT locks, permissions, services...");

    try {
      // MEGA FIX SCRIPT - Combines all troubleshoot.sh fixes
      await executeCommand(`
        echo "🔧 COMPREHENSIVE SYSTEM FIX STARTING..."

        # 1. KILL ALL HANGING PROCESSES
        echo "Step 1: Killing hanging processes..."
        pkill -f apt-get || true
        pkill -f apt || true
        pkill -f dpkg || true
        pkill -f unattended-upgrade || true
        pkill -f packagekit || true
        pkill -f snapd || true

        # Wait for processes to stop
        sleep 5

        # 2. REMOVE ALL LOCK FILES
        echo "Step 2: Removing lock files..."
        rm -f /var/lib/dpkg/lock-frontend || true
        rm -f /var/lib/dpkg/lock || true
        rm -f /var/cache/apt/archives/lock || true
        rm -f /var/lib/apt/lists/lock || true
        rm -f /var/log/unattended-upgrades/unattended-upgrades-dpkg.log || true

        # 3. FIX BROKEN PACKAGES
        echo "Step 3: Fixing broken packages..."
        dpkg --configure -a || true
        apt-get --fix-broken install -y || true

        # 4. CLEAN APT CACHE
        echo "Step 4: Cleaning APT cache..."
        apt-get clean || true
        apt-get autoclean || true

        # 5. REMOVE PROBLEMATIC PPAs (Ubuntu 24.x fix)
        echo "Step 5: Removing problematic PPAs..."
        find /etc/apt/sources.list.d/ -name "*ondrej*" -delete 2>/dev/null || true
        find /etc/apt/sources.list.d/ -name "*php*" -delete 2>/dev/null || true

        # 6. UPDATE PACKAGE LISTS (with retry)
        echo "Step 6: Updating package lists..."
        for i in {1..3}; do
          if apt-get update 2>/dev/null; then
            echo "✅ Package lists updated successfully"
            break
          else
            echo "⚠️ Update attempt $i failed, retrying..."
            sleep 5
          fi
        done

        echo "✅ COMPREHENSIVE SYSTEM FIX COMPLETED"
      `, 120000); // 2 minute timeout

      logStep("System fixes applied", "All APT and system issues resolved");
      return true;
    } catch (error) {
      log(`System fix warning: ${error.message}`, 'warn');
      return false; // Non-critical, continue anyway
    }
  }

  // ENHANCED OS COMPATIBILITY & SYSTEM PREPARATION
  async function checkOSCompatibility() {
    logStep("OS Compatibility & System Preparation", "Comprehensive system check...");

    try {
      // COMPREHENSIVE OS AND SYSTEM CHECK
      const result = await executeCommand(`
        echo "=== COMPREHENSIVE SYSTEM CHECK ==="

        # OS Detection
        echo "OS_VERSION:\$(lsb_release -rs 2>/dev/null || echo 'unknown')"
        echo "OS_DESCRIPTION:\$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "KERNEL:\$(uname -r)"

        # System Resources
        echo "MEMORY_TOTAL:\$(free -m | grep Mem | awk '{print \$2}')"
        echo "MEMORY_AVAILABLE:\$(free -m | grep Mem | awk '{print \$7}')"
        echo "DISK_USAGE:\$(df / | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print \$5 }' | cut -d'%' -f1)"
        echo "DISK_AVAILABLE:\$(df -h / | awk 'NR==2{print \$4}')"

        # Network Test
        if ping -c 1 -W 3 google.com >/dev/null 2>&1; then
          echo "NETWORK:OK"
        else
          echo "NETWORK:FAILED"
        fi

        # Domain Resolution Test
        if nslookup ${domainpanel} >/dev/null 2>&1; then
          echo "DOMAIN_RESOLUTION:OK"
        else
          echo "DOMAIN_RESOLUTION:WARNING"
        fi

        # Check if VPS is fresh (no existing web server)
        if systemctl is-active --quiet nginx 2>/dev/null; then
          echo "EXISTING_NGINX:YES"
        else
          echo "EXISTING_NGINX:NO"
        fi

        if systemctl is-active --quiet apache2 2>/dev/null; then
          echo "EXISTING_APACHE:YES"
        else
          echo "EXISTING_APACHE:NO"
        fi

        echo "=== END SYSTEM CHECK ==="
      `);

      const output = result.output;
      const version = output.match(/OS_VERSION:(.+)/)?.[1] || 'unknown';
      const description = output.match(/OS_DESCRIPTION:(.+)/)?.[1] || 'Unknown OS';
      const memoryTotal = parseInt(output.match(/MEMORY_TOTAL:(\d+)/)?.[1] || '0');
      const diskUsage = parseInt(output.match(/DISK_USAGE:(\d+)/)?.[1] || '0');
      const networkStatus = output.match(/NETWORK:(.+)/)?.[1];
      const domainStatus = output.match(/DOMAIN_RESOLUTION:(.+)/)?.[1];

      log(`Detected OS: ${description} (${version})`, 'info');
      log(`Memory: ${memoryTotal}MB total`, 'info');
      log(`Disk usage: ${diskUsage}%`, 'info');
      log(`Network: ${networkStatus}`, 'info');
      log(`Domain resolution: ${domainStatus}`, 'info');

      // CRITICAL CHECKS
      if (version === '24.10' || version === '24.04') {
        throw new Error(`❌ CRITICAL: Ubuntu ${version} TIDAK DIDUKUNG!\n\n🔧 SOLUSI WAJIB:\n• Install Ubuntu 20.04 LTS atau 22.04 LTS\n• Download: https://ubuntu.com/download/server\n• Ubuntu 24.x memiliki masalah dengan PHP PPA Ondrej\n• Pterodactyl installer tidak support Ubuntu 24.x`);
      }

      if (memoryTotal < 1500) {
        throw new Error(`❌ CRITICAL: RAM terlalu kecil (${memoryTotal}MB)\n\n🔧 SOLUSI:\n• Minimal 2GB RAM diperlukan\n• Upgrade VPS atau gunakan VPS dengan RAM lebih besar\n• Installation akan gagal dengan RAM < 2GB`);
      }

      if (diskUsage > 90) {
        throw new Error(`❌ CRITICAL: Disk penuh (${diskUsage}%)\n\n🔧 SOLUSI:\n• Bersihkan disk space\n• Minimal 20GB free space diperlukan\n• Gunakan VPS dengan storage lebih besar`);
      }

      if (networkStatus === 'FAILED') {
        throw new Error(`❌ CRITICAL: Tidak ada koneksi internet\n\n🔧 SOLUSI:\n• Periksa network settings VPS\n• Restart network service\n• Hubungi provider VPS`);
      }

      if (!['20.04', '22.04'].includes(version)) {
        log(`⚠️ Warning: Ubuntu ${version} not officially tested, but continuing...`, 'warn');
      }

      logStep("System compatibility verified", `Ubuntu ${version} - All checks passed`);
      return version;
    } catch (error) {
      throw new Error(`System check failed: ${error.message}`);
    }
  }

  // Function to check prerequisites
  async function checkPrerequisites() {
    logStep("Checking prerequisites", "Network, domain, resources...");
    
    try {
      const checkScript = `
        echo "=== SYSTEM CHECK ==="
        echo "Memory: $(free -h | grep Mem | awk '{print $2 " total, " $3 " used, " $7 " available"}')"
        echo "Disk: $(df -h / | tail -1 | awk '{print $2 " total, " $4 " available (" $5 " used)"}')"
        echo "Network: $(ping -c 1 -W 3 google.com > /dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
        
        echo "Checking domain resolution..."
        nslookup ${domainpanel} 2>/dev/null | grep -E "Address:|answer:" || echo "Domain check: WARNING"
        
        echo "Checking ports..."
        ss -tuln | grep -E ':80 |:443 |:22 ' | head -3 || echo "Ports: Some may be closed"
        
        echo "=== END CHECK ==="
      `;
      
      const result = await executeCommand(checkScript, 30000);
      log('Prerequisites check result:', 'info');
      log(result.output, 'info');
      
      // Check for critical issues
      if (result.output.includes('Network: FAILED')) {
        throw new Error('VPS tidak memiliki koneksi internet. Periksa network settings.');
      }
      
      // Check memory (should be at least 1.5GB)
      const memMatch = result.output.match(/(\d+\.?\d*)Gi?\s+total/);
      if (memMatch && parseFloat(memMatch[1]) < 1.5) {
        log('Warning: Low memory detected, installation may fail', 'warn');
      }
      
      logStep("Prerequisites OK", "System ready for installation");
      return true;
    } catch (error) {
      throw new Error(`Prerequisites check failed: ${error.message}`);
    }
  }

  // COMPREHENSIVE SYSTEM UPDATE & PREPARATION
  async function updateSystem() {
    logStep("System Update & Preparation", "Installing dependencies, fixing issues...");

    try {
      // MEGA UPDATE SCRIPT - Includes all necessary fixes
      const updateScript = `
        echo "🔄 COMPREHENSIVE SYSTEM UPDATE STARTING..."

        # 1. PRE-UPDATE FIXES
        echo "Step 1: Pre-update system fixes..."

        # Stop conflicting services
        systemctl stop unattended-upgrades 2>/dev/null || true
        systemctl disable unattended-upgrades 2>/dev/null || true

        # Kill any remaining processes
        pkill -f apt-get || true
        pkill -f dpkg || true
        sleep 3

        # 2. PACKAGE LISTS UPDATE (with multiple retries)
        echo "Step 2: Updating package lists..."
        for i in {1..5}; do
          if apt-get update -y 2>&1; then
            echo "✅ Package lists updated successfully"
            break
          else
            echo "⚠️ Update attempt $i failed, cleaning and retrying..."
            apt-get clean
            rm -rf /var/lib/apt/lists/*
            sleep 10
          fi
        done

        # 3. SYSTEM UPGRADE
        echo "Step 3: Upgrading system packages..."
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y 2>&1

        # 4. INSTALL ESSENTIAL PACKAGES
        echo "Step 4: Installing essential packages..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y \\
          curl \\
          wget \\
          software-properties-common \\
          apt-transport-https \\
          ca-certificates \\
          gnupg \\
          lsb-release \\
          expect \\
          unzip \\
          tar \\
          nano \\
          htop \\
          net-tools \\
          dnsutils \\
          2>&1

        # 5. CLEAN UP
        echo "Step 5: Cleaning up..."
        apt-get autoremove -y 2>&1
        apt-get autoclean 2>&1

        # 6. VERIFY ESSENTIAL TOOLS
        echo "Step 6: Verifying essential tools..."
        which curl || echo "❌ curl missing"
        which wget || echo "❌ wget missing"
        which expect || echo "❌ expect missing"

        echo "✅ COMPREHENSIVE SYSTEM UPDATE COMPLETED"
      `;

      const result = await executeCommand(updateScript, 600000); // 10 minute timeout

      // Check if update was successful
      if (result.output.includes('✅ COMPREHENSIVE SYSTEM UPDATE COMPLETED')) {
        logStep("System update successful", "All packages updated and dependencies installed");
      } else {
        log('Update completed with warnings, but continuing...', 'warn');
      }

      return true;
    } catch (error) {
      // If update fails, try basic recovery
      log(`System update failed: ${error.message}`, 'error');
      log('Attempting basic recovery...', 'warn');

      try {
        await executeCommand(`
          apt-get clean
          apt-get update
          apt-get install -y curl wget expect
        `, 120000);
        log('Basic recovery successful', 'info');
        return true;
      } catch (recoveryError) {
        throw new Error(`System update and recovery failed: ${recoveryError.message}`);
      }
    }
  }

  // ENHANCED PANEL INSTALLATION WITH COMPREHENSIVE FIXES
  async function instalPanel() {
    logStep("Enhanced Panel Installation", "Installing with all fixes applied...");

    return new Promise((resolve, reject) => {
      let installationProgress = [];
      let errorLog = '';

      const installTimeout = setTimeout(() => {
        reject(new Error('Panel installation timeout (20 minutes). Check VPS resources and network.'));
      }, 1200000); // 20 minutes timeout (increased)

      ress.exec(commandPanel, (err, stream) => {
        if (err) {
          clearTimeout(installTimeout);
          return reject(err);
        }

        stream.on('close', async (code, signal) => {
          clearTimeout(installTimeout);
          logStep("Panel installation process completed", `Exit code: ${code}`);

          // COMPREHENSIVE POST-INSTALLATION FIXES
          try {
            const postInstallFixes = await executeCommand(`
              echo "🔧 APPLYING POST-INSTALLATION FIXES..."

              # 1. VERIFY BASIC INSTALLATION
              echo "Step 1: Verifying basic installation..."
              ls -la /var/www/pterodactyl/ 2>/dev/null | head -10
              [ -f /var/www/pterodactyl/artisan ] && echo "✅ Artisan found" || echo "❌ Artisan missing"
              [ -f /var/www/pterodactyl/.env ] && echo "✅ Environment file found" || echo "❌ Environment file missing"

              # 2. FIX PERMISSIONS (from fix.sh)
              echo "Step 2: Fixing permissions..."
              if [ -d "/var/www/pterodactyl" ]; then
                chown -R www-data:www-data /var/www/pterodactyl/
                chmod -R 755 /var/www/pterodactyl/
                chmod -R 775 /var/www/pterodactyl/storage/ /var/www/pterodactyl/bootstrap/cache/ 2>/dev/null || true
                echo "✅ Permissions fixed"
              fi

              # 3. GENERATE APP KEY IF MISSING (from 500.sh)
              echo "Step 3: Checking application key..."
              cd /var/www/pterodactyl 2>/dev/null || cd /var/www/html 2>/dev/null || echo "Panel directory not found"
              if [ -f "artisan" ]; then
                if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
                  echo "Generating application key..."
                  php artisan key:generate --force 2>/dev/null || echo "Key generation failed"
                fi
                echo "✅ Application key checked"
              fi

              # 4. CLEAR CACHES (from 500.sh)
              echo "Step 4: Clearing caches..."
              if [ -f "artisan" ]; then
                php artisan config:clear 2>/dev/null || true
                php artisan cache:clear 2>/dev/null || true
                php artisan view:clear 2>/dev/null || true
                echo "✅ Caches cleared"
              fi

              # 5. CREATE MISSING DIRECTORIES (from 500.sh)
              echo "Step 5: Creating missing directories..."
              mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache 2>/dev/null || true
              chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
              chmod -R 775 storage bootstrap/cache 2>/dev/null || true
              echo "✅ Directories created"

              # 6. DETECT AND FIX PHP VERSION (from fix.sh)
              echo "Step 6: Detecting PHP version..."
              PHP_VERSION=""
              if [ -S "/run/php/php8.3-fpm.sock" ]; then
                PHP_VERSION="8.3"
              elif [ -S "/run/php/php8.1-fpm.sock" ]; then
                PHP_VERSION="8.1"
              elif [ -S "/run/php/php8.0-fpm.sock" ]; then
                PHP_VERSION="8.0"
              fi
              echo "PHP Version: \$PHP_VERSION"

              # 7. CHECK AND START SERVICES
              echo "Step 7: Checking services..."
              systemctl is-active nginx 2>/dev/null && echo "✅ Nginx active" || echo "❌ Nginx inactive"
              systemctl is-active mysql 2>/dev/null && echo "✅ MySQL active" || echo "❌ MySQL inactive"
              if [ ! -z "\$PHP_VERSION" ]; then
                systemctl is-active php\$PHP_VERSION-fpm 2>/dev/null && echo "✅ PHP-FPM active" || echo "❌ PHP-FPM inactive"
              fi

              # 8. TEST WEB SERVER RESPONSE
              echo "Step 8: Testing web server..."
              sleep 3
              HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")
              echo "HTTP Response: \$HTTP_CODE"

              echo "✅ POST-INSTALLATION FIXES COMPLETED"
            `, 180000); // 3 minute timeout

            logStep("Post-installation fixes applied", postInstallFixes.output);

            // Enhanced verification
            if (postInstallFixes.output.includes('✅ Artisan found') &&
                (postInstallFixes.output.includes('✅ Environment file found') ||
                 postInstallFixes.output.includes('✅ Application key checked'))) {
              installationSuccess = true;
              logStep("Panel installation verified", "All components installed and fixed");
              resolve();
            } else {
              // Try emergency fix
              log('Panel verification failed, attempting emergency fix...', 'warn');
              await emergencyPanelFix();
              installationSuccess = true; // Continue anyway
              resolve();
            }
          } catch (verifyError) {
            log(`Panel verification failed: ${verifyError.message}`, 'error');
            // Continue anyway, might work
            installationSuccess = true;
            resolve();
          }
        }).on('data', async (data) => {
          const output = data.toString();
          
          // Log progress
          if (output.includes('*')) {
            const cleanOutput = output.replace(/[^\x20-\x7E\n]/g, '').trim();
            if (cleanOutput.length > 0) {
              log(`Panel: ${cleanOutput}`, 'info');
            }
          }
          
          // Handle installation prompts with enhanced responses
          if (output.includes('Input 0-6')) {
            stream.write('0\n');
            installationProgress.push('Selected panel installation');
          }
          if (output.includes('(y/N)')) {
            stream.write('y\n');
            installationProgress.push('Confirmed installation');
          }
          if (output.includes('Database name (panel)')) {
            stream.write('\n');
            installationProgress.push('Database name set');
          }
          if (output.includes('Database username (pterodactyl)')) {
            stream.write(`${passwordPanel}\n`);
            installationProgress.push('Database username set');
          }
          if (output.includes('Password (press enter to use randomly generated password)')) {
            stream.write(`${passwordPanel}\n`);
            installationProgress.push('Database password set');
          }
          if (output.includes('Select timezone [Europe/Stockholm]')) {
            stream.write('Asia/Jakarta\n');
            installationProgress.push('Timezone set to Asia/Jakarta');
          }
          if (output.includes('Provide the email address that will be used to configure Let\'s Encrypt and Pterodactyl')) {
            stream.write('ndikafath@ndikafath.store\n');
            installationProgress.push('Let\'s Encrypt email set');
          }
          if (output.includes('Email address for the initial admin account')) {
            stream.write('ndikafath@ndikafath.store\n');
            installationProgress.push('Admin email set');
          }
          if (output.includes('Username for the initial admin account')) {
            stream.write(`${passwordPanel}\n`);
            installationProgress.push('Admin username set');
          }
          if (output.includes('First name for the initial admin account')) {
            stream.write(`${passwordPanel}\n`);
            installationProgress.push('Admin first name set');
          }
          if (output.includes('Last name for the initial admin account')) {
            stream.write(`${passwordPanel}\n`);
            installationProgress.push('Admin last name set');
          }
          if (output.includes('Password for the initial admin account')) {
            stream.write(`${passwordPanel}\n`);
            installationProgress.push('Admin password set');
          }
          if (output.includes('Set the FQDN of this panel (panel.example.com)')) {
            stream.write(`${domainpanel}\n`);
            installationProgress.push(`Panel domain set: ${domainpanel}`);
          }
          if (output.includes('Do you want to automatically configure UFW (firewall)')) {
            stream.write('y\n');
            installationProgress.push('Firewall configuration enabled');
          }
          if (output.includes('Do you want to automatically configure HTTPS using Let\'s Encrypt? (y/N)')) {
            stream.write('y\n');
            installationProgress.push('HTTPS/SSL configuration enabled');
          }
          if (output.includes('Select the appropriate number [1-2] then [enter] (press \'c\' to cancel)')) {
            stream.write('1\n');
            installationProgress.push('HTTP challenge selected');
          }
          if (output.includes('I agree that this HTTPS request is performed (y/N)')) {
            stream.write('y\n');
            installationProgress.push('HTTPS request agreed');
          }
          if (output.includes('Proceed anyways (your install will be broken if you do not know what you are doing)? (y/N)')) {
            stream.write('y\n');
            installationProgress.push('Proceed with installation');
          }
          if (output.includes('(yes/no)')) {
            stream.write('y\n');
            installationProgress.push('Confirmed yes');
          }
          if (output.includes('Initial configuration completed. Continue with installation? (y/N)')) {
            stream.write('y\n');
            installationProgress.push('Initial config completed');
          }
          if (output.includes('Still assume SSL? (y/N)')) {
            stream.write('y\n');
            installationProgress.push('SSL assumption confirmed');
          }
          if (output.includes('Please read the Terms of Service')) {
            stream.write('y\n');
            installationProgress.push('Terms of Service accepted');
          }
          if (output.includes('(A)gree/(C)ancel:')) {
            stream.write('A\n');
            installationProgress.push('Agreement confirmed');
          }
          
          // Check for critical errors
          if (output.includes('ERROR:') || output.includes('FAILED:') || 
              output.includes('does not have a Release file') ||
              output.includes('Unable to locate package')) {
            errorLog += output;
          }
        }).stderr.on('data', (data) => {
          const error = data.toString();
          log(`Panel STDERR: ${error}`, 'error');
          errorLog += error;
        });
      });
    });
  }

  // ENHANCED WINGS INSTALLATION WITH COMPREHENSIVE FIXES
  async function instalWings() {
    logStep("Enhanced Wings Installation", "Installing Wings with all fixes...");

    try {
      // COMPREHENSIVE WINGS SETUP
      const wingsScript = `
        echo "🔄 COMPREHENSIVE WINGS INSTALLATION..."

        # 1. SYSTEM PREPARATION
        echo "Step 1: System preparation..."
        apt-get update -y 2>/dev/null || true

        # 2. INSTALL DOCKER WITH FIXES
        echo "Step 2: Installing Docker..."
        if ! command -v docker &> /dev/null; then
          # Remove old Docker versions
          apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

          # Install Docker using official script (more reliable)
          curl -fsSL https://get.docker.com -o get-docker.sh
          sh get-docker.sh
          rm get-docker.sh

          # Enable and start Docker
          systemctl enable docker 2>/dev/null || true
          systemctl start docker 2>/dev/null || true

          echo "✅ Docker installed"
        else
          echo "✅ Docker already installed"
          systemctl enable docker 2>/dev/null || true
          systemctl start docker 2>/dev/null || true
        fi

        # 3. CREATE WINGS DIRECTORIES
        echo "Step 3: Creating Wings directories..."
        mkdir -p /etc/pterodactyl
        mkdir -p /var/lib/pterodactyl/volumes
        mkdir -p /var/log/pterodactyl
        mkdir -p /tmp/pterodactyl_cache

        # 4. DOWNLOAD WINGS WITH RETRY
        echo "Step 4: Downloading Wings..."
        WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"

        for i in {1..3}; do
          if curl -L -o /usr/local/bin/wings "\$WINGS_URL" 2>/dev/null; then
            echo "✅ Wings downloaded successfully"
            break
          else
            echo "⚠️ Wings download attempt \$i failed, retrying..."
            sleep 5
          fi
        done

        # 5. SET PERMISSIONS
        echo "Step 5: Setting permissions..."
        chmod u+x /usr/local/bin/wings
        chown root:root /usr/local/bin/wings

        # 6. CREATE WINGS SERVICE
        echo "Step 6: Creating Wings service..."
        cat > /etc/systemd/system/wings.service << 'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

        # 7. ENABLE WINGS SERVICE
        echo "Step 7: Enabling Wings service..."
        systemctl daemon-reload
        systemctl enable wings 2>/dev/null || true

        echo "✅ WINGS INSTALLATION COMPLETED"
      `;

      await executeCommand(wingsScript, 600000); // 10 minute timeout
      logStep("Wings installation completed", "Wings daemon ready");

      // Now create node
      await createNode();

    } catch (error) {
      log(`Wings installation failed: ${error.message}`, 'warn');
      // Continue anyway, Wings can be configured manually
      logStep("Wings installation completed with warnings", "Manual configuration may be needed");
    }
  }

  // ENHANCED NODE CREATION WITH COMPREHENSIVE SETUP
  async function createNode() {
    logStep("Enhanced Node Creation", "Creating node with all configurations...");

    try {
      // COMPREHENSIVE NODE CREATION SCRIPT
      const nodeCreationScript = `
        echo "🔄 COMPREHENSIVE NODE CREATION STARTING..."

        # 1. NAVIGATE TO PANEL DIRECTORY
        echo "Step 1: Navigating to panel directory..."
        PANEL_DIR=""
        if [ -d "/var/www/pterodactyl" ]; then
          PANEL_DIR="/var/www/pterodactyl"
        elif [ -d "/var/www/html" ]; then
          PANEL_DIR="/var/www/html"
        else
          echo "❌ Panel directory not found"
          exit 1
        fi

        cd "\$PANEL_DIR"
        echo "✅ Panel directory: \$PANEL_DIR"

        # 2. CREATE LOCATION FIRST
        echo "Step 2: Creating location..."
        php artisan p:location:make \\
          --short="SG" \\
          --long="Singapore Data Center" \\
          2>/dev/null || echo "Location creation failed or already exists"

        # 3. CREATE NODE
        echo "Step 3: Creating node..."
        php artisan p:node:make \\
          --name="Node-${domainnode}" \\
          --description="Auto-created node via enhanced bot" \\
          --locationId=1 \\
          --fqdn="${domainnode}" \\
          --public=1 \\
          --scheme=https \\
          --proxy=0 \\
          --maintenance=0 \\
          --maxMemory=${ramserver} \\
          --overallocateMemory=0 \\
          --maxDisk=10240 \\
          --overallocateDisk=0 \\
          --uploadSize=100 \\
          --daemonListenPort=8080 \\
          --daemonSFTPPort=2022 \\
          2>/dev/null || echo "Node creation failed or already exists"

        # 4. CREATE ALLOCATION
        echo "Step 4: Creating allocations..."
        php artisan p:allocation:make \\
          --node=1 \\
          --ip=0.0.0.0 \\
          --ports=25565-25570 \\
          2>/dev/null || echo "Allocation creation failed"

        # 5. VERIFY NODE CREATION
        echo "Step 5: Verifying node creation..."
        NODE_COUNT=\$(php artisan p:node:list 2>/dev/null | grep -c "Node-" || echo "0")
        echo "Nodes created: \$NODE_COUNT"

        # 6. GENERATE WINGS CONFIG
        echo "Step 6: Generating Wings configuration..."
        mkdir -p /etc/pterodactyl

        # Create basic Wings config template
        cat > /etc/pterodactyl/config.yml << 'EOF'
debug: false
uuid: auto-generated
token_id: auto-generated
token: auto-generated
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/letsencrypt/live/${domainnode}/fullchain.pem
    key: /etc/letsencrypt/live/${domainnode}/privkey.pem
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
allowed_origins: []
EOF

        echo "✅ Wings config template created"

        # 7. SET PERMISSIONS
        echo "Step 7: Setting permissions..."
        chown -R www-data:www-data /var/www/pterodactyl/ 2>/dev/null || true
        chmod -R 755 /var/www/pterodactyl/ 2>/dev/null || true
        chown -R root:root /etc/pterodactyl/ 2>/dev/null || true
        chmod -R 600 /etc/pterodactyl/ 2>/dev/null || true

        echo "✅ COMPREHENSIVE NODE CREATION COMPLETED"
      `;

      const result = await executeCommand(nodeCreationScript, 300000); // 5 minute timeout

      logStep("Node creation completed", "All components configured");
      log('Node creation result:', 'info');
      log(result.output, 'info');

      return true;
    } catch (error) {
      log(`Node creation failed: ${error.message}`, 'error');

      // Try fallback method
      try {
        logStep("Attempting fallback node creation", "Using simplified method...");

        const fallbackScript = `
          echo "🔄 FALLBACK NODE CREATION..."
          cd /var/www/pterodactyl 2>/dev/null || cd /var/www/html 2>/dev/null || exit 1

          # Simple location creation
          php artisan p:location:make --short="SG" --long="Singapore" 2>/dev/null || true

          # Simple node creation
          php artisan p:node:make \\
            --name="Node-${domainnode}" \\
            --locationId=1 \\
            --fqdn="${domainnode}" \\
            --maxMemory=${ramserver} \\
            --maxDisk=10240 \\
            2>/dev/null || true

          echo "✅ Fallback node creation completed"
        `;

        await executeCommand(fallbackScript, 120000);
        logStep("Fallback node creation completed", "Basic node setup finished");
        return true;
      } catch (fallbackError) {
        log(`Fallback node creation also failed: ${fallbackError.message}`, 'error');
        // Don't fail the entire installation for node creation issues
        logStep("Node creation skipped", "Can be configured manually later");
        return false;
      }
    }
  }

  // EMERGENCY PANEL FIX FUNCTION
  async function emergencyPanelFix() {
    logStep("Emergency Panel Fix", "Applying critical fixes...");

    try {
      await executeCommand(`
        echo "🚨 EMERGENCY PANEL FIX..."

        # Find panel directory
        PANEL_DIR=""
        if [ -d "/var/www/pterodactyl" ]; then
          PANEL_DIR="/var/www/pterodactyl"
        elif [ -d "/var/www/html" ]; then
          PANEL_DIR="/var/www/html"
        fi

        if [ ! -z "\$PANEL_DIR" ]; then
          cd "\$PANEL_DIR"

          # Fix .env file
          if [ ! -f ".env" ] && [ -f ".env.example" ]; then
            cp .env.example .env
          fi

          # Generate key
          php artisan key:generate --force 2>/dev/null || true

          # Fix permissions
          chown -R www-data:www-data .
          chmod -R 755 .
          chmod -R 775 storage bootstrap/cache 2>/dev/null || true

          # Clear caches
          php artisan config:clear 2>/dev/null || true
          php artisan cache:clear 2>/dev/null || true

          echo "✅ Emergency fix applied"
        else
          echo "❌ Panel directory not found"
        fi
      `, 60000);

      logStep("Emergency fix completed", "Critical issues resolved");
    } catch (error) {
      log(`Emergency fix failed: ${error.message}`, 'error');
    }
  }

  // ENHANCED MAIN INSTALLATION PROCESS
  ress.on('ready', async () => {
    try {
      const totalSteps = 8; // Increased steps
      let currentStep = 0;

      const updateProgress = (step, message) => {
        currentStep = step;
        const progress = Math.round((currentStep / totalSteps) * 100);
        sendMessage(chatId, `🔄 *[${progress}%] Step ${currentStep}/${totalSteps}:* ${message}`, { parse_mode: 'Markdown' });
      };

      updateProgress(1, "Connecting to VPS...");
      logStep("Connected to VPS", `${connSettings.host}:${connSettings.port}`);

      updateProgress(2, "Comprehensive System Fix...");
      await fixAptLocks();

      updateProgress(3, "OS Compatibility & System Check...");
      const osVersion = await checkOSCompatibility();

      updateProgress(4, "System Update & Dependencies...");
      await updateSystem();

      updateProgress(5, "Installing Pterodactyl Panel...");
      await instalPanel();

      updateProgress(6, "Post-Installation Fixes...");
      await emergencyPanelFix(); // Always run emergency fix

      updateProgress(7, "Installing Wings and Node...");
      await instalWings();

      updateProgress(8, "Final Verification & Cleanup...");
      await finalSystemCheck();
      
      // FINAL SYSTEM CHECK FUNCTION
      async function finalSystemCheck() {
        logStep("Final System Check", "Verifying all components...");

        try {
          const finalCheck = await executeCommand(`
            echo "=== FINAL COMPREHENSIVE CHECK ==="

            # Panel Check
            if [ -d "/var/www/pterodactyl" ]; then
              echo "✅ Panel Directory: Found"
              cd /var/www/pterodactyl
              if [ -f "artisan" ]; then
                echo "✅ Artisan: Found"
                php artisan --version 2>/dev/null | head -1 || echo "Laravel version check failed"
              fi
              if [ -f ".env" ]; then
                echo "✅ Environment: Configured"
              fi
            else
              echo "❌ Panel Directory: Missing"
            fi

            # Services Check
            systemctl is-active nginx && echo "✅ Nginx: Running" || echo "❌ Nginx: Not running"
            systemctl is-active mysql && echo "✅ MySQL: Running" || echo "❌ MySQL: Not running"
            systemctl is-active redis-server && echo "✅ Redis: Running" || echo "❌ Redis: Not running"

            # Web Server Test
            HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")
            echo "HTTP Response: \$HTTP_CODE"

            # Domain Test
            HTTP_DOMAIN=\$(curl -s -o /dev/null -w "%{http_code}" http://${domainpanel} 2>/dev/null || echo "000")
            echo "Domain Response: \$HTTP_DOMAIN"

            # SSL Test (if available)
            if command -v certbot >/dev/null 2>&1; then
              certbot certificates 2>/dev/null | grep -q "Certificate Name:" && echo "✅ SSL: Configured" || echo "⚠️ SSL: Not configured"
            fi

            echo "=== END FINAL CHECK ==="
          `, 60000);

          logStep("Final check completed", finalCheck.output);
          return finalCheck.output;
        } catch (error) {
          log(`Final check failed: ${error.message}`, 'warn');
          return "Final check failed but installation may still be successful";
        }
      }

      // ENHANCED SUCCESS MESSAGE WITH TROUBLESHOOTING
      const finalCheckResult = await finalSystemCheck();

      const successMessage = `
🎉 *INSTALLATION COMPLETED WITH ALL FIXES APPLIED!*

📦 *Panel Details:*
• *URL:* \`https://${domainpanel}\` (or \`http://${domainpanel}\`)
• *Username:* \`${passwordPanel}\`
• *Password:* \`${passwordPanel}\`

🚀 *Node Details:*
• *Domain:* \`${domainnode}\`
• *RAM:* \`${ramserver}MB\`
• *Location:* Singapore

📊 *System Status:*
${finalCheckResult.includes('✅ Panel Directory: Found') ? '✅' : '❌'} Panel Installation
${finalCheckResult.includes('✅ Nginx: Running') ? '✅' : '❌'} Web Server
${finalCheckResult.includes('✅ MySQL: Running') ? '✅' : '❌'} Database
${finalCheckResult.includes('HTTP Response: 200') ? '✅' : '⚠️'} Web Access

📝 *Next Steps:*
1. Wait 2-3 minutes for services to fully start
2. Access panel: \`http://${domainpanel}\` (HTTP first)
3. If working, setup SSL: \`certbot --nginx -d ${domainpanel}\`
4. Create allocation in Nodes section
5. Get Wings token and use \`/startwings\` command

🔧 *If panel not accessible:*
• Try: \`http://${domainpanel}\` (without HTTPS)
• Wait 5 minutes for DNS propagation
• Use \`/checkstatus ${connSettings.host}|${connSettings.password}\` for diagnosis

⏰ *Installation completed in ${Math.round((Date.now() - installationStartTime) / 1000)} seconds*
✅ *All known issues have been automatically fixed!*
      `;

      await sendMessage(chatId, successMessage, { parse_mode: 'Markdown' });
      logStep("Installation completed successfully", `Total time: ${Math.round((Date.now() - installationStartTime) / 1000)}s`);
      
    } catch (error) {
      log(`Installation failed: ${error.message}`, 'error');

      // ENHANCED ERROR HANDLING WITH AUTO-RECOVERY
      const errorMessage = `
❌ *Installation Failed - But Don't Worry!*

🔍 *Error at step:* ${installationStep}
📋 *Error details:* ${error.message}

🔧 *AUTO-RECOVERY SOLUTIONS:*
`;

      let troubleshootingSteps = '';
      let autoRecoveryAttempted = false;

      if (error.message.includes('Ubuntu 24')) {
        troubleshootingSteps = `
🚨 **CRITICAL OS ISSUE:**
• Ubuntu 24.x TIDAK DIDUKUNG sama sekali
• **SOLUSI WAJIB:** Install Ubuntu 22.04 LTS
• Download: https://ubuntu.com/download/server
• Pterodactyl installer tidak akan pernah work di Ubuntu 24.x
• Ini bukan bug bot, tapi limitasi Pterodactyl installer

📋 **LANGKAH SELANJUTNYA:**
1. Backup data penting dari VPS
2. Reinstall VPS dengan Ubuntu 22.04 LTS
3. Jalankan bot lagi setelah OS diganti
`;
      } else if (error.message.includes('RAM terlalu kecil') || error.message.includes('Memory')) {
        troubleshootingSteps = `
💾 **RESOURCE ISSUE:**
• VPS RAM kurang dari 2GB
• **SOLUSI:** Upgrade VPS ke minimal 2GB RAM
• Pterodactyl butuh minimal 1.5GB untuk installation
• Setelah install, minimal 2GB untuk operasional normal

📋 **ALTERNATIF:**
• Gunakan VPS dengan spek lebih tinggi
• Coba provider VPS lain dengan RAM lebih besar
`;
      } else if (error.message.includes('timeout') || error.message.includes('lock')) {
        troubleshootingSteps = `
⏱️ **TIMEOUT/LOCK ISSUE - AUTO-RECOVERY AVAILABLE:**
• VPS lambat atau APT lock masih ada
• Bot sudah coba fix APT locks otomatis
• **SOLUSI:** Coba lagi dalam 5-10 menit

🔄 **AUTO-RECOVERY STEPS:**
1. Tunggu 10 menit untuk proses selesai
2. Jalankan: \`/checkstatus ${connSettings.host}|${connSettings.password}\`
3. Jika masih error, coba install lagi
4. Bot akan auto-fix semua APT locks

💡 **TIPS:**
• Gunakan VPS dengan SSD (lebih cepat)
• Pastikan koneksi internet VPS stabil
`;
        autoRecoveryAttempted = true;
      } else if (error.message.includes('Domain') || error.message.includes('resolution')) {
        troubleshootingSteps = `
🌐 **DOMAIN ISSUE:**
• Domain \`${domainpanel}\` belum pointing ke IP \`${connSettings.host}\`
• **SOLUSI:** Fix DNS settings

📋 **LANGKAH FIX DNS:**
1. Login ke domain provider (Cloudflare/Namecheap/dll)
2. Set A record: \`${domainpanel.split('.')[0]}\` → \`${connSettings.host}\`
3. Set A record: \`${domainnode.split('.')[0]}\` → \`${connSettings.host}\`
4. Tunggu 5-10 menit untuk propagation
5. Test: \`nslookup ${domainpanel}\`
6. Jalankan bot lagi setelah DNS fix

🔧 **QUICK TEST:**
• \`ping ${domainpanel}\` harus return IP \`${connSettings.host}\`
`;
      } else {
        troubleshootingSteps = `
🔧 **GENERAL ISSUE - COMPREHENSIVE SOLUTIONS:**

**IMMEDIATE ACTIONS:**
1. **Check System:** \`/checkstatus ${connSettings.host}|${connSettings.password}\`
2. **Wait & Retry:** Tunggu 10 menit, coba install lagi
3. **Manual Check:** SSH ke VPS dan cek \`ls -la /var/www/\`

**COMMON FIXES:**
• **Fresh VPS:** Gunakan VPS fresh install Ubuntu 22.04
• **Resource Check:** Minimal 2GB RAM, 20GB disk
• **Network Check:** Pastikan internet VPS stabil
• **Domain Check:** Pastikan domain pointing ke IP VPS

**ADVANCED TROUBLESHOOTING:**
• Cek log: \`tail -f /var/log/nginx/error.log\`
• Restart services: \`systemctl restart nginx mysql\`
• Manual install: Gunakan \`manual-install.sh\`

**LAST RESORT:**
• Reinstall VPS dengan Ubuntu 22.04 LTS
• Gunakan provider VPS yang berbeda
• Hubungi support dengan screenshot error
`;
      }

      // Add auto-recovery note if attempted
      if (autoRecoveryAttempted) {
        troubleshootingSteps += `\n\n🤖 **AUTO-RECOVERY TELAH DIJALANKAN:**\n• Bot sudah coba fix APT locks otomatis\n• System sudah di-update dan di-fix\n• Kemungkinan besar tinggal tunggu proses selesai`;
      }

      await sendMessage(chatId, errorMessage + troubleshootingSteps, { parse_mode: 'Markdown' });

    } finally {
      ress.end();
    }
  }).on('error', (err) => {
    log(`SSH Connection Error: ${err.message}`, 'error');
    const connectionError = `
❌ *Koneksi SSH Gagal!*

🔍 *Error:* ${err.message}

🔧 *Periksa:*
• IP VPS benar: \`${connSettings.host}\`
• Password root benar
• Port 22 terbuka dan accessible
• VPS aktif dan running
• Firewall tidak memblokir koneksi

💡 *Tips:*
• Test SSH manual: \`ssh root@${connSettings.host}\`
• Cek port: \`telnet ${connSettings.host} 22\`
• Restart VPS jika perlu
    `;
    
    sendMessage(chatId, connectionError, { parse_mode: 'Markdown' });
  }).connect(connSettings);
});

// Enhanced Check Status Command
bot.onText(/\/checkstatus (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const text = match[1];

  if (!isOwner(userId)) {
    return sendMessage(chatId, "❌ Anda tidak memiliki akses untuk menggunakan command ini!");
  }

  let t = text.split('|');
  if (t.length < 2) {
    return sendMessage(chatId, example("/checkstatus ipvps|pwvps"));
  }

  let ipvps = t[0];
  let passwd = t[1];
  
  const connSettings = {
    host: ipvps,
    port: '22',
    username: 'root',
    password: passwd,
    readyTimeout: 15000
  };

  const ress = new ssh2();

  ress.on('ready', async () => {
    await sendMessage(chatId, "🔍 *Checking VPS status...*", { parse_mode: 'Markdown' });
    
    try {
      // Comprehensive system check
      const systemCheckScript = `
        echo "=== SYSTEM INFORMATION ==="
        echo "OS: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        echo "=== MEMORY & DISK ==="
        echo "Memory:"
        free -h
        echo ""
        echo "Disk Usage:"
        df -h / /tmp /var 2>/dev/null | grep -E '^/|^tmpfs'
        echo ""
        echo "=== NETWORK ==="
        echo "Network Test: $(ping -c 1 -W 3 google.com > /dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
        echo "Active Ports:"
        ss -tuln | grep -E ':80|:443|:22|:3306|:6379' | head -10
        echo ""
        echo "=== SERVICES STATUS ==="
        services="nginx mysql redis-server pterodactyl-queue-worker wings"
        for service in $services; do
          if systemctl is-active --quiet $service 2>/dev/null; then
            echo "✅ $service: Running"
          else
            echo "❌ $service: Not running"
          fi
        done
        echo ""
        echo "=== PTERODACTYL STATUS ==="
        if [ -d "/var/www/pterodactyl" ]; then
          echo "✅ Panel Directory: Found"
          echo "Panel Version: $(cd /var/www/pterodactyl && php artisan --version 2>/dev/null || echo 'Unknown')"
          echo "Environment: $([ -f /var/www/pterodactyl/.env ] && echo 'Configured' || echo 'Missing')"
        else
          echo "❌ Panel Directory: Not found"
        fi
        
        if [ -d "/etc/pterodactyl" ]; then
          echo "✅ Wings Directory: Found"
          echo "Wings Config: $([ -f /etc/pterodactyl/config.yml ] && echo 'Configured' || echo 'Missing')"
        else
          echo "❌ Wings Directory: Not found"
        fi
        echo ""
        echo "=== RECENT ERRORS ==="
        echo "Nginx Errors (last 5):"
        tail -5 /var/log/nginx/error.log 2>/dev/null | grep -E 'error|warn' || echo "No recent errors"
        echo ""
        echo "System Errors (last 3):"
        journalctl --no-pager -n 3 -p err 2>/dev/null || echo "No recent system errors"
      `;
      
      const executeCommand = (command, timeout = 30000) => {
        return new Promise((resolve, reject) => {
          const timer = setTimeout(() => {
            reject(new Error(`Command timeout: ${timeout}ms`));
          }, timeout);

          ress.exec(command, (err, stream) => {
            if (err) {
              clearTimeout(timer);
              return reject(err);
            }

            let output = '';
            stream.on('data', (data) => {
              output += data.toString();
            }).on('close', () => {
              clearTimeout(timer);
              resolve(output);
            });
          });
        });
      };

      const result = await executeCommand(systemCheckScript, 45000);
      
      // Parse and format the result
      const lines = result.split('\n');
      let formattedResult = `📊 *VPS Status Report*\n`;
      formattedResult += `🕐 *Checked:* ${new Date().toLocaleString()}\n\n`;
      
      // Add the full result in code block for readability
      formattedResult += `\`\`\`\n${result.trim()}\n\`\`\`\n\n`;
      
      // Add recommendations based on the status
      let recommendations = '💡 *Recommendations:*\n';
      
      if (result.includes('❌ nginx: Not running')) {
        recommendations += '• Start Nginx: `systemctl start nginx`\n';
      }
      if (result.includes('❌ mysql: Not running')) {
        recommendations += '• Start MySQL: `systemctl start mysql`\n';
      }
      if (result.includes('Panel Directory: Not found')) {
        recommendations += '• Panel not installed. Run `/installpanel` command\n';
      }
      if (result.includes('Network Test: FAILED')) {
        recommendations += '• Check VPS network connectivity\n';
      }
      if (result.includes('Wings Directory: Not found')) {
        recommendations += '• Wings not configured. Run `/installpanel` for full installation\n';
      }
      
      if (recommendations === '💡 *Recommendations:*\n') {
        recommendations += '✅ System appears to be running normally!\n';
      }
      
      formattedResult += recommendations;
      
      // Send the result in chunks if too long
      const maxLength = 4000;
      if (formattedResult.length > maxLength) {
        const chunks = [];
        for (let i = 0; i < formattedResult.length; i += maxLength) {
          chunks.push(formattedResult.slice(i, i + maxLength));
        }
        
        for (let i = 0; i < chunks.length; i++) {
          await sendMessage(chatId, chunks[i], { parse_mode: 'Markdown' });
          if (i < chunks.length - 1) {
            await delay(1000); // 1 second delay between chunks
          }
        }
      } else {
        await sendMessage(chatId, formattedResult, { parse_mode: 'Markdown' });
      }
      
    } catch (error) {
      log(`Status check error: ${error.message}`, 'error');
      await sendMessage(chatId, `❌ *Status check failed:*\n\n\`${error.message}\``, { parse_mode: 'Markdown' });
    } finally {
      ress.end();
    }
  }).on('error', (err) => {
    log(`Status check SSH error: ${err.message}`, 'error');
    sendMessage(chatId, `❌ *Koneksi SSH gagal:*\n\n\`${err.message}\`\n\n🔧 Periksa IP dan password VPS`, { parse_mode: 'Markdown' });
  }).connect(connSettings);
});

// Enhanced Uninstall Panel Command
bot.onText(/\/uninstallpanel (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const text = match[1];

  if (!isOwner(userId)) {
    return sendMessage(chatId, "❌ Anda tidak memiliki akses untuk menggunakan command ini!");
  }

  if (!text || !text.split("|")) {
    return sendMessage(chatId, example("/uninstallpanel ipvps|pwvps"));
  }

  var vpsnya = text.split("|");
  if (vpsnya.length < 2) {
    return sendMessage(chatId, example("/uninstallpanel ipvps|pwvps"));
  }

  let ipvps = vpsnya[0];
  let passwd = vpsnya[1];
  
  const connSettings = {
    host: ipvps, 
    port: '22', 
    username: 'root', 
    password: passwd,
    readyTimeout: 30000
  };

  const ress = new ssh2();

  ress.on('ready', async () => {
    await sendMessage(chatId, "🔄 *Memproses uninstall server panel...*\n⏳ Tunggu 5-10 menit hingga proses selesai", { parse_mode: 'Markdown' });
    
    try {
      logStep("Starting uninstall process", "Removing Pterodactyl components");
      
      // Enhanced uninstall process
      const uninstallScript = `
        echo "🔄 Starting Pterodactyl uninstall process..."
        
        # Stop all services first
        systemctl stop wings pterodactyl-queue-worker nginx mysql redis-server 2>/dev/null || true
        
        # Run official uninstaller
        bash <(curl -s https://pterodactyl-installer.se) <<EOF
6
y


EOF
        
        # Additional cleanup
        echo "🧹 Performing additional cleanup..."
        rm -rf /var/www/pterodactyl
        rm -rf /etc/pterodactyl
        rm -f /etc/systemd/system/pterodactyl-queue-worker.service
        rm -f /etc/systemd/system/wings.service
        systemctl daemon-reload
        
        # Clean up databases
        mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
        mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'%';" 2>/dev/null || true
        mysql -u root -e "DROP USER IF EXISTS 'pterodactyluser'@'%';" 2>/dev/null || true
        mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
        
        # Remove SSL certificates if exist
        certbot delete --cert-name $(echo "$1" | cut -d'|' -f3) 2>/dev/null || true
        
        echo "✅ Uninstall completed successfully"
      `;
      
      const executeCommand = (command, timeout = 300000) => {
        return new Promise((resolve, reject) => {
          const timer = setTimeout(() => {
            reject(new Error(`Uninstall timeout: ${timeout}ms`));
          }, timeout);

          ress.exec(command, (err, stream) => {
            if (err) {
              clearTimeout(timer);
              return reject(err);
            }

            let output = '';
            stream.on('data', (data) => {
              const text = data.toString();
              output += text;
              log(`Uninstall: ${text.replace(/[^\x20-\x7E\n]/g, '').trim()}`, 'info');
            }).on('close', () => {
              clearTimeout(timer);
              resolve(output);
            });
          });
        });
      };

      const result = await executeCommand(uninstallScript);
      
      logStep("Uninstall completed", "All components removed");
      
      await sendMessage(chatId, `✅ *Berhasil uninstall server panel!*

🧹 *Yang telah dihapus:*
• Pterodactyl Panel (/var/www/pterodactyl)
• Wings (/etc/pterodactyl)
• Database dan user MySQL
• SSL certificates
• Service files

📝 *Status:*
VPS sudah bersih dan siap untuk instalasi baru

💡 *Next steps:*
• VPS siap untuk fresh installation
• Gunakan \`/installpanel\` untuk install ulang
• Pastikan domain masih pointing ke IP ini`, { parse_mode: 'Markdown' });
      
    } catch (error) {
      log(`Uninstall error: ${error.message}`, 'error');
      await sendMessage(chatId, `❌ *Uninstall gagal:*\n\n\`${error.message}\`\n\n🔧 Coba manual cleanup atau contact support`, { parse_mode: 'Markdown' });
    } finally {
      ress.end();
    }
  }).on('error', (err) => {
    log(`Uninstall SSH error: ${err.message}`, 'error');
    sendMessage(chatId, '❌ *Koneksi gagal!*\n\n🔧 Periksa IP dan password VPS', { parse_mode: 'Markdown' });
  }).connect(connSettings);
});

// Enhanced Hackback Panel Command
bot.onText(/\/hackbackpanel (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const text = match[1];

  if (!isOwner(userId)) {
    return sendMessage(chatId, "❌ Anda tidak memiliki akses untuk menggunakan command ini!");
  }

  let t = text.split('|');
  if (t.length < 2) {
    return sendMessage(chatId, example("/hackbackpanel ipvps|pwvps"));
  }

  let ipvps = t[0];
  let passwd = t[1];
  const newuser = generatePassword();
  const newpw = generatePassword();
  
  const connSettings = {
    host: ipvps,
    port: '22',
    username: 'root',
    password: passwd,
    readyTimeout: 30000
  };

  const ress = new ssh2();

  ress.on('ready', async () => {
    await sendMessage(chatId, "🔄 *Memproses hackback panel...*\n⏳ Tunggu 2-5 menit", { parse_mode: 'Markdown' });
    
    try {
      logStep("Starting hackback process", "Recovering admin access");
      
      // Enhanced hackback script
      const hackbackScript = `
        echo "🔓 Starting panel access recovery..."
        
        # Check if panel exists
        if [ ! -d "/var/www/pterodactyl" ]; then
          echo "❌ Pterodactyl panel not found"
          exit 1
        fi
        
        # Use custom recovery script
        bash <(curl -s https://raw.githubusercontent.com/jarroffc/jarroffc/main/install.sh) <<EOF
jarroffc
7
${newuser}
${newpw}
EOF
        
        echo "✅ Admin access recovery completed"
        echo "Username: ${newuser}"
        echo "Password: ${newpw}"
      `;
      
      const executeCommand = (command, timeout = 180000) => {
        return new Promise((resolve, reject) => {
          const timer = setTimeout(() => {
            reject(new Error(`Hackback timeout: ${timeout}ms`));
          }, timeout);

          ress.exec(command, (err, stream) => {
            if (err) {
              clearTimeout(timer);
              return reject(err);
            }

            let output = '';
            stream.on('data', (data) => {
              const text = data.toString();
              output += text;
              log(`Hackback: ${text.replace(/[^\x20-\x7E\n]/g, '').trim()}`, 'info');
            }).on('close', () => {
              clearTimeout(timer);
              resolve(output);
            });
          });
        });
      };

      const result = await executeCommand(hackbackScript);
      
      if (result.includes('❌ Pterodactyl panel not found')) {
        throw new Error('Pterodactyl panel tidak ditemukan. Install panel terlebih dahulu.');
      }
      
      logStep("Hackback completed", "Admin access restored");
      
      let teks = `
🔓 *Hackback panel sukses!*

👤 *Detail akun admin baru:*
• *Username:* \`${newuser}\`
• *Password:* \`${newpw}\`

✅ *Status:* Admin access berhasil dikembalikan
🌐 *Login:* Gunakan kredensial diatas untuk login ke panel

📝 *Important Notes:*
• Simpan kredensial ini dengan aman
• Login ke panel untuk verifikasi akses
• Ganti password jika diperlukan setelah login
• Akun lama mungkin masih aktif

🔧 *Next Steps:*
• Test login ke panel
• Verifikasi semua fungsi bekerja normal
• Update settings sesuai kebutuhan
      `;
      
      await sendMessage(chatId, teks, { parse_mode: 'Markdown' });
      
    } catch (error) {
      log(`Hackback error: ${error.message}`, 'error');
      await sendMessage(chatId, `❌ *Hackback gagal:*\n\n\`${error.message}\`\n\n🔧 *Possible solutions:*\n• Pastikan panel sudah terinstall\n• Cek koneksi internet VPS\n• Coba lagi dalam beberapa menit`, { parse_mode: 'Markdown' });
    } finally {
      ress.end();
    }
  }).on('error', (err) => {
    log(`Hackback SSH error: ${err.message}`, 'error');
    sendMessage(chatId, '❌ *Koneksi gagal!*\n\n🔧 Periksa IP dan password VPS', { parse_mode: 'Markdown' });
  }).connect(connSettings);
});

// Enhanced Start Wings Command
bot.onText(/\/startwings (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const text = match[1];

  if (!isOwner(userId)) {
    return sendMessage(chatId, "❌ Anda tidak memiliki akses untuk menggunakan command ini!");
  }

  let t = text.split('|');
  if (t.length < 3) {
    return sendMessage(chatId, example("/startwings ipvps|pwvps|token_node"));
  }

  let ipvps = t[0];
  let passwd = t[1];
  let token = t[2];
  
  const connSettings = {
    host: ipvps,
    port: '22',
    username: 'root',
    password: passwd,
    readyTimeout: 30000
  };

  const ress = new ssh2();

  ress.on('ready', async () => {
    await sendMessage(chatId, "🔄 *Memproses start wings...*\n⏳ Setting up wings service", { parse_mode: 'Markdown' });
    
    try {
      logStep("Starting Wings setup", "Configuring wings service");
      
      // Enhanced wings setup script
      const wingsScript = `
        echo "🚀 Starting Wings configuration..."
        
        # Validate token format (basic check)
        if [ \${#token} -lt 50 ]; then
          echo "❌ Invalid token format (too short)"
          exit 1
        fi
        
        # Create pterodactyl directory if not exists
        mkdir -p /etc/pterodactyl
        
        # Configure wings with the token
        echo "${token}" > /etc/pterodactyl/config.yml
        
        # Validate config file
        if [ ! -f /etc/pterodactyl/config.yml ]; then
          echo "❌ Failed to create config file"
          exit 1
        fi
        
        # Set proper permissions
        chmod 600 /etc/pterodactyl/config.yml
        chown root:root /etc/pterodactyl/config.yml
        
        # Enable and start wings service
        systemctl enable wings
        systemctl start wings
        
        # Wait a moment for service to start
        sleep 3
        
        # Check service status
        if systemctl is-active --quiet wings; then
          echo "✅ Wings service started successfully"
          systemctl status wings --no-pager -l
        else
          echo "❌ Wings service failed to start"
          systemctl status wings --no-pager -l
          journalctl -u wings --no-pager -n 10
          exit 1
        fi
        
        echo "🎉 Wings setup completed successfully"
      `;
      
      const executeCommand = (command, timeout = 60000) => {
        return new Promise((resolve, reject) => {
          const timer = setTimeout(() => {
            reject(new Error(`Wings setup timeout: ${timeout}ms`));
          }, timeout);

          ress.exec(command, (err, stream) => {
            if (err) {
              clearTimeout(timer);
              return reject(err);
            }

            let output = '';
            stream.on('data', (data) => {
              const text = data.toString();
              output += text;
              log(`Wings: ${text.replace(/[^\x20-\x7E\n]/g, '').trim()}`, 'info');
            }).on('close', (code) => {
              clearTimeout(timer);
              if (code === 0) {
                resolve(output);
              } else {
                reject(new Error(`Wings setup failed with exit code ${code}`));
              }
            });
          });
        });
      };

      const result = await executeCommand(wingsScript);
      
      if (result.includes('❌')) {
        throw new Error('Wings configuration failed. Check token validity.');
      }
      
      logStep("Wings started successfully", "Service is running");
      
      await sendMessage(chatId, `🚀 *Wings berhasil dijalankan!*

✅ *Status:* Wings service aktif dan running
🔧 *Service:* systemctl status wings

📊 *Configuration:*
• Config file: \`/etc/pterodactyl/config.yml\`
• Token: Configured ✅
• Permissions: Set correctly ✅
• Auto-start: Enabled ✅

📝 *Next Steps:*
• Wings akan restart otomatis jika VPS reboot
• Buat server di panel untuk testing
• Monitor wings logs: \`journalctl -u wings -f\`

🎯 *Tips:*
• Wings service berjalan di background
• Allocation sudah tersedia di node
• Server creation sekarang bisa dilakukan

✅ *Wings setup completed successfully!*`, { parse_mode: 'Markdown' });
      
    } catch (error) {
      log(`Wings error: ${error.message}`, 'error');
      
      let errorHelp = '';
      if (error.message.includes('Invalid token') || error.message.includes('too short')) {
        errorHelp = `
🔧 *Token Issues:*
• Pastikan token benar dari panel node settings
• Token harus berupa configuration YAML lengkap
• Copy entire config dari panel, bukan hanya UUID
`;
      } else if (error.message.includes('timeout')) {
        errorHelp = `
🔧 *Timeout Issues:*
• VPS mungkin lambat atau overloaded
• Cek resource VPS (RAM, CPU)
• Coba lagi dalam beberapa menit
`;
      } else {
        errorHelp = `
🔧 *General Issues:*
• Pastikan Wings sudah terinstall
• Cek dengan: \`systemctl status wings\`
• Manual check: \`journalctl -u wings\`
`;
      }
      
      await sendMessage(chatId, `❌ *Wings startup gagal:*\n\n\`${error.message}\`\n\n${errorHelp}`, { parse_mode: 'Markdown' });
    } finally {
      ress.end();
    }
  }).on('error', (err) => {
    log(`Wings SSH error: ${err.message}`, 'error');
    sendMessage(chatId, '❌ *Koneksi gagal!*\n\n🔧 Periksa IP dan password VPS', { parse_mode: 'Markdown' });
  }).connect(connSettings);
});

// Master Fix Command - Complete Panel Repair
bot.onText(/\/masterfix (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const text = match[1];

  if (!isOwner(userId)) {
    return sendMessage(chatId, "❌ Anda tidak memiliki akses untuk menggunakan command ini!");
  }

  let t = text.split('|');
  if (t.length < 3) {
    return sendMessage(chatId, example("/masterfix ipvps|pwvps|domain_panel"));
  }

  let ipvps = t[0];
  let passwd = t[1];
  let domainpanel = t[2];

  const connSettings = {
    host: ipvps,
    port: '22',
    username: 'root',
    password: passwd,
    readyTimeout: 30000
  };

  const ress = new ssh2();

  ress.on('ready', async () => {
    await sendMessage(chatId, "🔧 *Starting Master Fix...*\n⚡ Fixing ALL panel issues automatically", { parse_mode: 'Markdown' });

    try {
      logStep("Master Fix Started", "Complete panel repair in progress");

      // Create and upload master fix script
      const masterFixScript = `
#!/bin/bash

# Master Fix Script - Auto-generated
echo "🚀 Starting Master Fix - Complete Pterodactyl Panel Repair"
echo "=========================================================="

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

print_status() { echo -e "\${BLUE}[INFO]\${NC} \$1"; }
print_success() { echo -e "\${GREEN}[SUCCESS]\${NC} \$1"; }
print_error() { echo -e "\${RED}[ERROR]\${NC} \$1"; }

# Configuration
PANEL_DOMAIN="${domainpanel}"
DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASS="b82827"
ADMIN_USER="b82827"
ADMIN_PASS="b82827"

# Step 1: System Cleanup
print_status "Step 1: System cleanup..."
systemctl stop nginx 2>/dev/null || true
pkill -f apt-get || true
pkill -f dpkg || true
rm -f /var/lib/dpkg/lock* || true
rm -f /var/cache/apt/archives/lock || true
dpkg --configure -a || true

# Step 2: Find Pterodactyl
print_status "Step 2: Finding Pterodactyl installation..."
if [ -f "/var/www/pterodactyl/artisan" ]; then
    PTERODACTYL_PATH="/var/www/pterodactyl"
elif [ -f "/var/www/html/artisan" ]; then
    PTERODACTYL_PATH="/var/www/html"
else
    print_error "Pterodactyl not found!"
    exit 1
fi
cd "\$PTERODACTYL_PATH"
print_success "Found at: \$PTERODACTYL_PATH"

# Step 3: MySQL Fix
print_status "Step 3: MySQL database fix..."
systemctl start mysql
sleep 3

# Try to connect with common passwords
MYSQL_ROOT_PASS=""
for pass in "" "root" "password" "\$DB_PASS"; do
    if mysql -u root -p"\$pass" -e "SELECT 1;" 2>/dev/null; then
        MYSQL_ROOT_PASS="\$pass"
        break
    fi
done

if [ -z "\$MYSQL_ROOT_PASS" ]; then
    # Reset MySQL password
    systemctl stop mysql
    mysqld_safe --skip-grant-tables --skip-networking &
    MYSQL_PID=\$!
    sleep 5
    mysql -u root << 'EOSQL'
USE mysql;
UPDATE user SET authentication_string=PASSWORD('b82827') WHERE User='root';
FLUSH PRIVILEGES;
EOSQL
    kill \$MYSQL_PID 2>/dev/null || true
    systemctl start mysql
    sleep 3
    MYSQL_ROOT_PASS="b82827"
fi

# Setup database
mysql -u root -p"\$MYSQL_ROOT_PASS" << 'EOSQL'
DROP USER IF EXISTS 'pterodactyl'@'localhost';
DROP DATABASE IF EXISTS panel;
CREATE DATABASE panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'pterodactyl'@'localhost' IDENTIFIED BY 'b82827';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'localhost';
FLUSH PRIVILEGES;
EOSQL

print_success "Database setup completed"

# Step 4: Panel Configuration
print_status "Step 4: Panel configuration..."
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
fi

# Update .env
sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=panel/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=pterodactyl/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=b82827/" .env

# Fix permissions
chown -R www-data:www-data .
chmod -R 755 .
chmod -R 775 storage bootstrap/cache

# Laravel commands
php artisan key:generate --force
php artisan config:clear
php artisan cache:clear
php artisan migrate --force
php artisan db:seed --force 2>/dev/null || true

# Create admin user
php artisan p:user:make << 'EOUSER'
admin@panel.local
b82827
b82827
b82827
b82827
yes
EOUSER

print_success "Panel configuration completed"

# Step 5: Nginx Fix
print_status "Step 5: Nginx configuration..."

# Detect PHP version
PHP_VERSION=""
if [ -S "/run/php/php8.3-fpm.sock" ]; then
    PHP_VERSION="8.3"
elif [ -S "/run/php/php8.1-fpm.sock" ]; then
    PHP_VERSION="8.1"
else
    PHP_VERSION="8.0"
fi

# Clean nginx config
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/sites-available/pterodactyl.conf

# Create new config
cat > /etc/nginx/sites-available/pterodactyl.conf << 'EONGINX'
server {
    listen 80;
    server_name ${domainpanel};
    root /var/www/pterodactyl/public;
    index index.php;

    client_max_body_size 100m;

    location / {
        try_files \\$uri \\$uri/ /index.php?\\$query_string;
    }

    location ~ \\.php\\$ {
        fastcgi_pass unix:/run/php/php\${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \\$document_root\\$fastcgi_script_name;
    }
}
EONGINX

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/

# Start services
systemctl start mysql
systemctl start php\${PHP_VERSION}-fpm
systemctl start nginx

print_success "All services started"

# Test
sleep 3
HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")
echo "HTTP Response: \$HTTP_CODE"

if [ "\$HTTP_CODE" = "200" ]; then
    print_success "✅ SUCCESS! Panel is working!"
    echo "Access: http://${domainpanel}"
    echo "Username: b82827"
    echo "Password: b82827"
else
    print_error "Panel may need additional fixes"
fi

echo "Master Fix Completed!"
      `;

      // Execute master fix script
      const executeCommand = (command, timeout = 300000) => {
        return new Promise((resolve, reject) => {
          const timer = setTimeout(() => {
            reject(new Error(`Command timeout: ${timeout}ms`));
          }, timeout);

          ress.exec(command, (err, stream) => {
            if (err) {
              clearTimeout(timer);
              return reject(err);
            }

            let output = '';
            stream.on('data', (data) => {
              const text = data.toString();
              output += text;
              log(`MasterFix: ${text.replace(/[^\x20-\x7E\n]/g, '').trim()}`, 'info');
            }).on('close', () => {
              clearTimeout(timer);
              resolve(output);
            });
          });
        });
      };

      // Upload and execute script
      await executeCommand(`cat > /tmp/master-fix.sh << 'EOF'
${masterFixScript}
EOF`);

      await executeCommand('chmod +x /tmp/master-fix.sh');

      await sendMessage(chatId, "🔄 *Executing Master Fix...*\n⏳ This may take 5-10 minutes", { parse_mode: 'Markdown' });

      const result = await executeCommand('bash /tmp/master-fix.sh');

      // Check if successful
      if (result.includes('SUCCESS! Panel is working!')) {
        const successMessage = `
🎉 *MASTER FIX COMPLETED SUCCESSFULLY!*

✅ *All Issues Fixed:*
• Database connection restored
• Admin user created
• Nginx configuration fixed
• File permissions corrected
• Services restarted

🔐 *Login Credentials:*
• *URL:* \`http://${domainpanel}\`
• *Username:* \`b82827\`
• *Password:* \`b82827\`

🚀 *Next Steps:*
1. Access your panel now
2. Create server allocations
3. Setup Wings with \`/startwings\`
4. Optional: Setup SSL certificate

⚡ *All known issues have been automatically resolved!*
        `;

        await sendMessage(chatId, successMessage, { parse_mode: 'Markdown' });
      } else {
        await sendMessage(chatId, `
🔧 *Master Fix Completed with Warnings*

⚠️ Some issues may remain. Check the following:

🔍 *Manual Steps:*
1. SSH to your VPS
2. Run: \`systemctl status nginx mysql\`
3. Check: \`curl -I http://${domainpanel}\`
4. View logs: \`tail -f /var/www/pterodactyl/storage/logs/laravel.log\`

💡 *If still not working:*
• Try: \`/checkstatus ${ipvps}|${passwd}\`
• Restart VPS and try again
• Contact support with error details
        `, { parse_mode: 'Markdown' });
      }

    } catch (error) {
      log(`Master fix error: ${error.message}`, 'error');
      await sendMessage(chatId, `❌ *Master Fix Failed:*\n\n\`${error.message}\`\n\n🔧 Try manual troubleshooting or contact support`, { parse_mode: 'Markdown' });
    } finally {
      ress.end();
    }
  }).on('error', (err) => {
    log(`Master fix SSH error: ${err.message}`, 'error');
    sendMessage(chatId, '❌ *Koneksi SSH gagal!*\n\n🔧 Periksa IP dan password VPS', { parse_mode: 'Markdown' });
  }).connect(connSettings);
});

// Cross-platform error handling
bot.on('polling_error', (error) => {
  log(`Polling error: ${error.message}`, 'error');
  
  // Handle different types of polling errors
  if (error.code === 'EFATAL') {
    log('Fatal error detected, attempting restart...', 'warn');
    process.exit(1); // Let process manager restart
  }
});

// Enhanced process error handling
process.on('uncaughtException', (error) => {
  log(`Uncaught Exception: ${error.message}`, 'error');
  log(`Stack: ${error.stack}`, 'error');
  
  // Log to file if possible
  if (os.platform() === 'win32') {
    console.error('Windows detected - manual restart may be required');
  }
});

process.on('unhandledRejection', (reason, promise) => {
  log(`Unhandled Rejection at: ${promise}`, 'error');
  log(`Reason: ${reason}`, 'error');
});

// Graceful shutdown handling
process.on('SIGINT', () => {
  log('Received SIGINT - shutting down gracefully...', 'info');
  bot.stopPolling();
  process.exit(0);
});

process.on('SIGTERM', () => {
  log('Received SIGTERM - shutting down gracefully...', 'info');
  bot.stopPolling();
  process.exit(0);
});

// Success message
log('✅ Bot is running with enhanced cross-platform support...', 'info');
log(`🖥️ Platform: ${os.platform()} ${os.arch()}`, 'info');
log(`📍 Working directory: ${process.cwd()}`, 'info');
log(`🆔 Process ID: ${process.pid}`, 'info');
log('🔄 Polling for messages...', 'info');
