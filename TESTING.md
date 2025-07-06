# 🧪 TESTING INSTRUCTIONS - Pterodactyl Bot v2.1

**Comprehensive testing guide for validating bot functionality**

## 📋 TESTING OVERVIEW

This guide covers all testing procedures to ensure the Pterodactyl Panel Installer Bot works correctly in your environment.

## 🔍 PRE-TESTING CHECKLIST

### **Environment Requirements:**
- [ ] Node.js v16+ installed
- [ ] Bot files in correct directory
- [ ] Internet connection available
- [ ] Telegram bot token configured
- [ ] Owner ID configured

### **Test VPS Requirements:**
- [ ] Ubuntu 20.04 or 22.04 LTS
- [ ] Fresh install (no existing applications)
- [ ] Minimum 2GB RAM, 20GB disk
- [ ] Root SSH access
- [ ] Domain pointing to VPS IP

---

## 🎯 AUTOMATED TESTING

### **Test 1: Bot Configuration Test**

```bash
# Linux/Mac
./test-bot.sh

# Windows
# Run the Node.js test manually:
node -e "
const config = require('./config.js');
console.log('BOT_TOKEN:', config.BOT_TOKEN ? 'CONFIGURED' : 'MISSING');
console.log('OWNER_ID:', config.OWNER_ID ? 'CONFIGURED' : 'MISSING');
console.log('Syntax check: PASSED');
"
```

**Expected Output:**
```
================================
 Bot Configuration Test v2.1
================================

[TEST] Checking Node.js installation...
[PASS] Node.js v18.17.0 (✓ >= v16)
[PASS] npm v9.6.7

[TEST] Checking project files...
[PASS] package.json exists
[PASS] bot.js exists
[PASS] config.js exists
[PASS] README.md exists

[TEST] Checking dependencies...
[PASS] node-telegram-bot-api installed
[PASS] ssh2 installed
[PASS] crypto installed

[TEST] Validating bot configuration...
[PASS] BOT_TOKEN configured (7884808609...)
[PASS] OWNER_ID configured (5476148500)

[TEST] Testing bot syntax...
[PASS] Bot syntax is valid

[TEST] Testing network connectivity...
[PASS] Internet connectivity OK
[PASS] Telegram API accessible

[TEST] Testing bot token validity...
[PASS] Bot token valid (Username: @YourBotName)

[TEST] Testing bot startup (10 second test)...
[PASS] Bot started successfully

================================
 Test Results Summary
================================
Total Tests: 8
Passed: 8
Failed: 0

[PASS] All tests passed! Bot is ready to use.

Next steps:
1. Start the bot: npm start (or ./start.sh)
2. Test with: /help command in Telegram
3. Try installation: /installpanel ip|pass|domain|node|ram
```

### **Test 2: System Diagnostic Test**

```bash
# Run comprehensive system check
sudo ./troubleshoot.sh
# Select option 11: Full system diagnostic
```

**Expected Output:**
```
🔧 Enhanced Pterodactyl Panel Troubleshooting Script v2.1

[STEP] Running: check_os
[SUCCESS] Ubuntu 22.04 is supported!

[STEP] Running: check_system_resources
[SUCCESS] Memory usage is normal: 25%

[STEP] Running: check_disk_space
[SUCCESS] Disk space is sufficient (15% used)

[STEP] Running: check_network
[SUCCESS] Internet connectivity: OK
[SUCCESS] DNS resolution: OK
[SUCCESS] Package repositories: OK
[SUCCESS] HTTPS connectivity: OK
[SUCCESS] All required ports are open

[STEP] Running: fix_repositories
[SUCCESS] APT locks and repository issues fixed!

========================================
DIAGNOSTIC SUMMARY
========================================
Total Checks: 8
Passed: 8
Warnings: 0
Failed: 0

[SUCCESS] All diagnostics passed! System is ready for Pterodactyl installation.
```

---

## 📱 TELEGRAM BOT TESTING

### **Test 3: Basic Bot Communication**

1. **Start the bot:**
   ```bash
   npm start
   # or
   ./start.sh
   ```

2. **Find your bot in Telegram:**
   - Search for your bot using token: `7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg`
   - Or contact @BotFather to get bot username

3. **Test basic commands:**

**Test Command: `/start`**
```
Expected Response:
🎯 Pterodactyl Panel Installer Bot v2.1

🔧 Commands tersedia:
• /installpanel - Install panel pterodactyl
• /uninstallpanel - Uninstall panel pterodactyl  
• /hackbackpanel - Hackback panel access
• /startwings - Start wings service
• /checkstatus - Check VPS status
• /help - Tampilkan menu bantuan

👤 Developer: NdikaFath ID
🖥️ Platform: Cross-platform Windows/Linux support
📝 Note: Bot ini hanya bisa digunakan oleh owner
```

**Test Command: `/help`**
```
Expected Response:
📖 Panduan Penggunaan Bot v2.1

🛠️ Install Panel (Enhanced):
/installpanel ipvps|pwvps|panel.com|node.com|ramserver
Contoh: /installpanel 1.2.3.4|password123|panel.tams.my.id|node.tams.my.id|8000

🔍 Check Status (NEW):
/checkstatus ipvps|pwvps
Contoh: /checkstatus 1.2.3.4|password123

[... full help text ...]
```

**Test Command: Invalid Command**
```
Send: /invalidcommand

Expected: No response (bot ignores unknown commands)
```

**Test Authorization:**
```
# Send command from different Telegram account (not owner)
Send: /help

Expected Response:
❌ Anda tidak memiliki akses untuk menggunakan command ini!
```

---

## 🖥️ VPS INSTALLATION TESTING

### **Test 4: Check Status Command**

**Test Command:**
```
/checkstatus your-vps-ip|your-root-password
```

**Expected Response (for clean VPS):**
```
🔍 Checking VPS status...

📊 VPS Status Report
🕐 Checked: 2025-07-06 14:30:00

```
=== SYSTEM INFORMATION ===
OS: Ubuntu 22.04.3 LTS
Kernel: 5.15.0-78-generic
Uptime: up 2 hours, 15 minutes
Load: 0.15, 0.10, 0.08

=== MEMORY & DISK ===
Memory:
              total        used        free      shared  buff/cache   available
Mem:          2.0Gi       400Mi       1.2Gi        5.0Mi       400Mi       1.4Gi

Disk Usage:
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        20G  2.1G   17G  12% /

=== NETWORK ===
Network Test: OK
Active Ports:
0.0.0.0:22      LISTEN
:::22           LISTEN

=== SERVICES STATUS ===
❌ nginx: Not running
❌ mysql: Not running
❌ redis-server: Not running
❌ pterodactyl-queue-worker: Not running
❌ wings: Not running

=== PTERODACTYL STATUS ===
❌ Panel Directory: Not found
❌ Wings Directory: Not found
```

💡 Recommendations:
✅ System appears ready for installation
• Run /installpanel for full installation
```

### **Test 5: Full Installation Test**

**⚠️ WARNING:** This test will install Pterodactyl on the target VPS. Use a test/disposable VPS only.

**Test Command:**
```
/installpanel your-vps-ip|root-password|panel.yourdomain.com|node.yourdomain.com|8000
```

**Expected Progress Messages:**
```
🔄 [14%] Step 1/7: Connecting to VPS...
🔄 [28%] Step 2/7: Fixing APT locks...
🔄 [42%] Step 3/7: Checking OS compatibility...
✅ Ubuntu 22.04 kompatibel
🔄 Melanjutkan instalasi...
🔄 [57%] Step 4/7: Checking prerequisites...
🔄 [71%] Step 5/7: Updating system packages...
🔄 [85%] Step 6/7: Installing Pterodactyl Panel...
🔄 [100%] Step 7/7: Installing Wings and creating node...

🎉 Installation Completed Successfully!

📦 Panel Details:
• URL: https://panel.yourdomain.com
• Username: abc123
• Password: def456

🚀 Node Details:
• Domain: node.yourdomain.com
• RAM: 8000MB
• Location: Singapore

📝 Next Steps:
1. Access panel: https://panel.yourdomain.com
2. Create allocation in Nodes section
3. Get Wings token from node settings
4. Use /startwings command with the token

⏰ Note: SSL certificate may take 2-3 minutes to be ready

✅ Installation completed in 847 seconds
```

**Installation Failure Test:**
```
# Test with Ubuntu 24.10 VPS
/installpanel ubuntu24-ip|password|domain|node|8000

Expected Response:
❌ Installation Failed!

🔍 Error at step: Checking OS compatibility
📋 Error details: Ubuntu 24.10 tidak didukung. Gunakan Ubuntu 20.04 atau 22.04

🔧 Troubleshooting:
• CRITICAL: Gunakan Ubuntu 20.04 atau 22.04 LTS
• Download: https://ubuntu.com/download/server
• Ubuntu 24.x tidak didukung oleh Pterodactyl installer
```

### **Test 6: Post-Installation Verification**

After successful installation, verify these:

**Test Panel Access:**
```bash
# Test HTTPS access
curl -I https://panel.yourdomain.com

Expected: HTTP/2 200 OK (or 301/302 redirect)
```

**Test Panel Login:**
1. Open: `https://panel.yourdomain.com`
2. Login with provided credentials
3. Verify dashboard loads correctly

**Test Services:**
```
/checkstatus your-vps-ip|password

Expected Response:
=== SERVICES STATUS ===
✅ nginx: Running
✅ mysql: Running  
✅ redis-server: Running
✅ pterodactyl-queue-worker: Running
❌ wings: Not running (normal, needs token)

=== PTERODACTYL STATUS ===
✅ Panel Directory: Found
Panel Version: Pterodactyl v1.11.11
Environment: Configured
✅ Wings Directory: Found
Wings Config: Missing (normal, needs token)

💡 Recommendations:
✅ System appears to be running normally!
```

---

## 🔧 ERROR TESTING

### **Test 7: APT Lock Simulation**

**Simulate APT lock issue:**
```bash
# On test VPS, create lock file
sudo touch /var/lib/dpkg/lock-frontend

# Try installation
/installpanel vps-ip|password|domain|node|8000

Expected: Bot should auto-resolve APT locks and continue installation
```

### **Test 8: Invalid Credentials Test**

**Test wrong SSH credentials:**
```
/checkstatus valid-ip|wrong-password

Expected Response:
❌ Koneksi SSH gagal!

🔧 Periksa:
• IP VPS benar: valid-ip
• Password root benar
• Port 22 terbuka dan accessible
• VPS aktif dan running
• Firewall tidak memblokir koneksi

💡 Tips:
• Test SSH manual: ssh root@valid-ip
• Cek port: telnet valid-ip 22
• Restart VPS jika perlu
```

### **Test 9: Network Issues Test**

**Test unreachable IP:**
```
/checkstatus 192.168.255.255|anypassword

Expected Response:
❌ Koneksi SSH gagal!

🔍 Error: Connection timeout

[... troubleshooting suggestions ...]
```

---

## 🚀 WINGS TESTING

### **Test 10: Wings Installation**

**Get Wings Token:**
1. Login to panel
2. Go to Admin → Nodes → Your Node
3. Go to Configuration tab
4. Copy the entire configuration

**Test Wings Command:**
```
/startwings vps-ip|password|wings-token-here

Expected Response:
🔄 Memproses start wings...
⏳ Setting up wings service

🚀 Wings berhasil dijalankan!

✅ Status: Wings service aktif dan running
🔧 Service: systemctl status wings

📊 Configuration:
• Config file: /etc/pterodactyl/config.yml
• Token: Configured ✅
• Permissions: Set correctly ✅
• Auto-start: Enabled ✅

📝 Next Steps:
• Wings akan restart otomatis jika VPS reboot
• Buat server di panel untuk testing
• Monitor wings logs: journalctl -u wings -f

🎯 Tips:
• Wings service berjalan di background
• Allocation sudah tersedia di node
• Server creation sekarang bisa dilakukan

✅ Wings setup completed successfully!
```

---

## 🧹 CLEANUP TESTING

### **Test 11: Uninstall Test**

**Test uninstall command:**
```
/uninstallpanel vps-ip|password

Expected Response:
🔄 Memproses uninstall server panel...
⏳ Tunggu 5-10 menit hingga proses selesai

✅ Berhasil uninstall server panel!

🧹 Yang telah dihapus:
• Pterodactyl Panel (/var/www/pterodactyl)
• Wings (/etc/pterodactyl)
• Database dan user MySQL
• SSL certificates
• Service files

📝 Status:
VPS sudah bersih dan siap untuk instalasi baru

💡 Next steps:
• VPS siap untuk fresh installation
• Gunakan /installpanel untuk install ulang
• Pastikan domain masih pointing ke IP ini
```

---

## 📊 PERFORMANCE TESTING

### **Test 12: Load Testing**

**Stress test bot:**
```bash
# Send multiple commands rapidly
for i in {1..5}; do
    # Send /help command via Telegram API
    curl -X POST "https://api.telegram.org/bot7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg/sendMessage" \
         -d "chat_id=5476148500&text=/help"
    sleep 1
done
```

**Expected:** Bot should handle all requests without crashing

### **Test 13: Long-Running Test**

**Test bot stability:**
```bash
# Run bot for extended period
./start.sh

# Monitor for 1 hour minimum
# Check memory usage: ps aux | grep node
# Check for crashes: tail -f logs/error.log
```

**Expected:** Bot should run without memory leaks or crashes

---

## 🎯 TESTING CHECKLIST

### **Pre-Testing:**
- [ ] All test files executable (`chmod +x *.sh`)
- [ ] Bot token and owner ID configured
- [ ] Test VPS available (Ubuntu 20.04/22.04)
- [ ] Domain configured and pointing to test VPS
- [ ] Internet connection stable

### **Configuration Testing:**
- [ ] `./test-bot.sh` passes all tests
- [ ] Bot responds to `/start` in Telegram
- [ ] Bot rejects commands from unauthorized users
- [ ] `/help` command shows complete help text

### **System Testing:**
- [ ] `sudo ./troubleshoot.sh` (option 11) passes
- [ ] `/checkstatus` works on clean VPS
- [ ] APT lock resolution works
- [ ] Network connectivity verified

### **Installation Testing:**
- [ ] Full installation completes successfully
- [ ] Panel accessible via HTTPS
- [ ] Admin login works with provided credentials
- [ ] All services running after installation
- [ ] Wings can be configured and started

### **Error Handling Testing:**
- [ ] Invalid credentials handled gracefully
- [ ] Network issues reported clearly
- [ ] Ubuntu 24.x properly rejected
- [ ] APT locks automatically resolved

### **Cleanup Testing:**
- [ ] Uninstall removes all components
- [ ] System clean after uninstall
- [ ] Reinstallation works after cleanup

---

## 🏆 SUCCESS CRITERIA

**Bot is considered FULLY TESTED when:**

1. **✅ All automated tests pass**
2. **✅ Complete installation works on Ubuntu 22.04**
3. **✅ Panel accessible and functional**
4. **✅ Wings can be configured and runs**
5. **✅ Error handling works correctly**
6. **✅ Uninstall cleans system completely**
7. **✅ Bot runs stable for extended period**
8. **✅ All edge cases handled gracefully**

## 📋 TEST REPORT TEMPLATE

```
PTERODACTYL BOT v2.1 TEST REPORT
================================

Test Date: 2025-07-06
Tester: Your Name
Environment: Windows 11 / Ubuntu 22.04 VPS

Configuration Tests:
□ test-bot.sh: PASS/FAIL
□ Bot communication: PASS/FAIL
□ Authorization: PASS/FAIL

System Tests:
□ OS compatibility: PASS/FAIL
□ APT lock resolution: PASS/FAIL
□ Network connectivity: PASS/FAIL

Installation Tests:
□ Fresh install Ubuntu 22.04: PASS/FAIL
□ Panel accessibility: PASS/FAIL
□ Wings configuration: PASS/FAIL

Error Handling Tests:
□ Invalid credentials: PASS/FAIL
□ Ubuntu 24.x rejection: PASS/FAIL
□ Network issues: PASS/FAIL

Performance Tests:
□ Load testing: PASS/FAIL
□ Memory usage: PASS/FAIL
□ Stability: PASS/FAIL

Overall Result: PASS/FAIL
Comments: [Your observations]

Recommendations: [Any improvements needed]
```

---

**🎉 TESTING COMPLETE!**

If all tests pass, your Pterodactyl Panel Installer Bot v2.1 is ready for production use!

**📞 Need Help?**
- Check logs for specific errors
- Run `./troubleshoot.sh` for automated fixes
- Review `SOLUTION-GUIDE.md` for common issues
- Use `/checkstatus` for real-time diagnostics
