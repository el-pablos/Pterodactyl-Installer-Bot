// Enhanced Configuration file for Pterodactyl Panel Installer Bot
module.exports = {
  // Bot configuration
  BOT_TOKEN: '7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg',
  OWNER_ID: 5476148500,
  
  // Email configuration
  DEFAULT_EMAIL: 'ndikafath@ndikafath.store',
  
  // Domain and API configuration
  subdomain: {
    "tams.my.id": {
      "zone": "1d1abb10b90d2fc25b6e2072ce721338",
      "apitoken": "qFwbfYQWm7iQt_DEJLFerGxJcqUQa_yoJSy61Wy-"
    }
  },
  
  // Installation scripts
  scripts: {
    pterodactyl: 'bash <(curl -s https://pterodactyl-installer.se)',
    createnode: 'bash <(curl -s https://raw.githubusercontent.com/jarroffc/jarroffc/main/createnode.sh)',
    hackback: 'bash <(curl -s https://raw.githubusercontent.com/jarroffc/jarroffc/main/install.sh)'
  },
  
  // Default settings
  defaults: {
    timezone: 'Asia/Jakarta',
    location: 'Singapore',
    locationDesc: 'Node By NdikaFath ID',
    nodeName: 'NdikaFath ID',
    locid: '1'
  },
  
  // Supported OS versions
  supportedOS: ['20.04', '22.04'],
  
  // Timeouts and delays (in milliseconds)
  timeouts: {
    ssh_connection: 30000,      // 30 seconds
    installation: 900000,       // 15 minutes
    wings_delay: 5000,          // 5 seconds delay before wings
    check_status: 10000         // 10 seconds for status check
  },
  
  // Error messages
  messages: {
    owner_only: "❌ Anda tidak memiliki akses untuk menggunakan command ini!",
    invalid_format: "❌ Format command tidak valid!",
    connection_failed: "❌ Koneksi SSH gagal! Periksa IP dan password VPS",
    os_not_supported: "❌ OS tidak didukung! Gunakan Ubuntu 20.04 atau 22.04",
    installation_failed: "❌ Instalasi gagal! Periksa log error",
    installation_success: "✅ Instalasi berhasil!",
    processing: "🔄 Memproses...",
    please_wait: "⏳ Tunggu beberapa menit hingga proses selesai"
  },
  
  // Log settings
  logging: {
    enabled: true,
    level: 'info', // debug, info, warn, error
    save_to_file: false
  }
};
