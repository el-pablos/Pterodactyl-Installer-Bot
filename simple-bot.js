const TelegramBot = require('node-telegram-bot-api');
const { Client: ssh2 } = require('ssh2');

// Bot configuration
const BOT_TOKEN = '7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg';
const OWNER_ID = 5476148500;

// Simple bot initialization with minimal config
const bot = new TelegramBot(BOT_TOKEN, { 
  polling: {
    interval: 2000,
    autoStart: false
  }
});

// Helper functions
const isOwner = (userId) => userId === OWNER_ID;
const sendMessage = (chatId, text, options = {}) => bot.sendMessage(chatId, text, options);
const log = (message, type = 'info') => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${type.toUpperCase()}] ${message}`);
};

// Start command
bot.onText(/\/start/, (msg) => {
  const chatId = msg.chat.id;
  sendMessage(chatId, `
🎯 *Pterodactyl Panel Installer Bot v2.1*

🔧 *Commands tersedia:*
• \`/masterfix\` - Complete panel fix (database, nginx, admin)
• \`/checkstatus\` - Check VPS status
• \`/help\` - Tampilkan menu bantuan

👤 *Developer:* NdikaFath ID
📝 *Note:* Bot ini hanya bisa digunakan oleh owner
  `, { parse_mode: 'Markdown' });
});

// Master Fix Command
bot.onText(/\/masterfix (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const text = match[1];

  if (!isOwner(userId)) {
    return sendMessage(chatId, "❌ Anda tidak memiliki akses untuk menggunakan command ini!");
  }

  let t = text.split('|');
  if (t.length < 3) {
    return sendMessage(chatId, "Contoh penggunaan:\n/masterfix ipvps|pwvps|domain_panel");
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
              output += data.toString();
            }).on('close', () => {
              clearTimeout(timer);
              resolve(output);
            });
          });
        });
      };

      // Create and run master fix script
      const masterFixScript = `
#!/bin/bash
echo "🚀 Master Fix Starting..."

# Find Pterodactyl
if [ -f "/var/www/pterodactyl/artisan" ]; then
    PTERODACTYL_PATH="/var/www/pterodactyl"
elif [ -f "/var/www/html/artisan" ]; then
    PTERODACTYL_PATH="/var/www/html"
else
    echo "❌ Pterodactyl not found!"
    exit 1
fi

cd "$PTERODACTYL_PATH"
echo "✅ Found Pterodactyl at: $PTERODACTYL_PATH"

# Fix MariaDB/MySQL
systemctl stop mariadb mysql 2>/dev/null || true
systemctl set-environment MYSQLD_OPTS="--skip-grant-tables --skip-networking" 2>/dev/null || true
systemctl start mariadb mysql 2>/dev/null || true
sleep 5

# Reset database
mysql -u root << 'EOF'
USE mysql;
UPDATE user SET password=PASSWORD('b82827') WHERE User='root';
FLUSH PRIVILEGES;
EOF

systemctl unset-environment MYSQLD_OPTS 2>/dev/null || true
systemctl restart mariadb mysql 2>/dev/null || true
sleep 3

# Setup database
mysql -u root -pb82827 << 'EOF'
DROP USER IF EXISTS 'pterodactyl'@'localhost';
DROP DATABASE IF EXISTS panel;
CREATE DATABASE panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'pterodactyl'@'localhost' IDENTIFIED BY 'b82827';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'localhost';
FLUSH PRIVILEGES;
EOF

# Configure .env
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
fi

sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=panel/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=pterodactyl/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=b82827/" .env

# Fix permissions
chown -R www-data:www-data .
chmod -R 755 .
chmod -R 775 storage bootstrap/cache

# Laravel setup
php artisan key:generate --force
php artisan config:clear
php artisan cache:clear
php artisan migrate --force

# Create admin user
mysql -u root -pb82827 panel << 'EOF'
INSERT INTO users (uuid, username, email, name_first, name_last, password, root_admin, language, created_at, updated_at) 
VALUES (
    UUID(),
    'b82827',
    'admin@panel.local',
    'b82827',
    'b82827',
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    1,
    'en',
    NOW(),
    NOW()
) ON DUPLICATE KEY UPDATE 
    password = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    root_admin = 1;
EOF

# Fix Nginx
PHP_VERSION="8.3"
if [ ! -S "/run/php/php8.3-fpm.sock" ]; then
    PHP_VERSION="8.1"
fi

rm -f /etc/nginx/sites-enabled/*
cat > /etc/nginx/sites-available/pterodactyl.conf << 'EONGINX'
server {
    listen 80;
    server_name ${domainpanel};
    root /var/www/pterodactyl/public;
    index index.php;
    
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
systemctl start mariadb mysql
systemctl start php\${PHP_VERSION}-fpm
systemctl start nginx

# Test
sleep 3
HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")

if [ "\$HTTP_CODE" = "200" ]; then
    echo "✅ SUCCESS! Panel is working!"
    echo "URL: http://${domainpanel}"
    echo "Username: b82827"
    echo "Password: b82827"
else
    echo "⚠️ HTTP Response: \$HTTP_CODE"
fi

echo "Master Fix Completed!"
      `;

      await executeCommand(`cat > /tmp/master-fix.sh << 'EOF'\n${masterFixScript}\nEOF`);
      await executeCommand('chmod +x /tmp/master-fix.sh');
      
      await sendMessage(chatId, "🔄 *Executing Master Fix...*\n⏳ This may take 5-10 minutes", { parse_mode: 'Markdown' });
      
      const result = await executeCommand('bash /tmp/master-fix.sh');

      if (result.includes('SUCCESS! Panel is working!')) {
        await sendMessage(chatId, `
🎉 *MASTER FIX COMPLETED SUCCESSFULLY!*

✅ *All Issues Fixed:*
• Database connection restored
• Admin user created
• Nginx configuration fixed
• File permissions corrected

🔐 *Login Credentials:*
• *URL:* \`http://${domainpanel}\`
• *Username:* \`b82827\`
• *Password:* \`b82827\`

🚀 *Panel is ready to use!*
        `, { parse_mode: 'Markdown' });
      } else {
        await sendMessage(chatId, `🔧 *Master Fix completed with warnings*\n\nCheck manually: \`http://${domainpanel}\``, { parse_mode: 'Markdown' });
      }
      
    } catch (error) {
      await sendMessage(chatId, `❌ *Master Fix Failed:*\n\n\`${error.message}\``, { parse_mode: 'Markdown' });
    } finally {
      ress.end();
    }
  }).on('error', (err) => {
    sendMessage(chatId, '❌ *Koneksi SSH gagal!*\n\n🔧 Periksa IP dan password VPS', { parse_mode: 'Markdown' });
  }).connect(connSettings);
});

// Error handling
bot.on('polling_error', (error) => {
  log(`Polling error: ${error.message}`, 'error');
});

// Start bot
async function startBot() {
  try {
    await bot.startPolling();
    log('🚀 Simple Bot Started Successfully!', 'info');
    log('📋 Available commands: /start, /masterfix', 'info');
  } catch (error) {
    log(`Failed to start bot: ${error.message}`, 'error');
    process.exit(1);
  }
}

startBot();
