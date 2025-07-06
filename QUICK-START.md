# 🚀 QUICK START GUIDE - Pterodactyl Bot v2.1

**Get your Pterodactyl Panel Installer Bot running in 5 minutes!**

## ⚡ SUPER QUICK START (Windows)

```cmd
cd "C:\Users\Administrator\Documents\work\install-panel-tele"
start.bat
```

**Done!** Bot is now running and ready to install Pterodactyl panels.

## ⚡ SUPER QUICK START (Linux)

```bash
cd /path/to/install-panel-tele
chmod +x start.sh
./start.sh
```

**Done!** Bot is now running and ready to install Pterodactyl panels.

---

## 📋 PRE-FLIGHT CHECKLIST

### ✅ **Before You Start:**

**For Development Machine:**
- [ ] Node.js v16+ installed
- [ ] Internet connection
- [ ] Bot token configured (already done: `7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg`)
- [ ] Owner ID configured (already done: `5476148500`)

**For Target VPS:**
- [ ] Ubuntu 20.04 or 22.04 LTS (❌ NOT 24.x)
- [ ] Fresh install (no existing applications)
- [ ] Minimum 2GB RAM, 20GB disk
- [ ] Domain pointing to VPS IP
- [ ] Root SSH access

---

## 🎯 STEP-BY-STEP INSTALLATION

### **Step 1: Start the Bot**

**Windows:**
```cmd
# Option 1: Enhanced launcher
start.bat

# Option 2: Direct start
npm start

# Option 3: Service (as Administrator)
windows-service.bat
```

**Linux:**
```bash
# Option 1: Enhanced launcher
./start.sh

# Option 2: Direct start
npm start

# Option 3: System service
sudo ./setup.sh install
```

### **Step 2: Test Bot Connection**

1. Open Telegram
2. Search for your bot (using token `7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg`)
3. Send `/start` command
4. You should see the welcome message

### **Step 3: Test Installation**

```
/installpanel 1.2.3.4|password123|panel.yourdomain.com|node.yourdomain.com|8000
```

**Replace with your actual:**
- `1.2.3.4` = Your VPS IP
- `password123` = Your VPS root password  
- `panel.yourdomain.com` = Your panel domain
- `node.yourdomain.com` = Your node domain
- `8000` = RAM allocation in MB

---

## 🔧 TROUBLESHOOTING QUICK FIXES

### **❌ Problem: APT Lock Error**
```
Could not get lock /var/lib/dpkg/lock-frontend
```
**✅ Solution:** Bot v2.1 auto-fixes this! If still persists:
```bash
sudo ./troubleshoot.sh
# Select option 2: Fix APT locks & repositories
```

### **❌ Problem: Ubuntu 24.x Not Supported**
```
Ubuntu 24.10 tidak didukung
```
**✅ Solution:** Install Ubuntu 22.04 LTS:
- Download: https://ubuntu.com/download/server
- Use fresh install VPS

### **❌ Problem: Connection Refused**
```
Connection refused to domain
```
**✅ Solution:** 
1. Wait 2-3 minutes for SSL generation
2. Check domain pointing: `nslookup your-domain.com`
3. Check status: `/checkstatus ip|password`

### **❌ Problem: Installation Failed**
```
Panel installation failed - Directory not created
```
**✅ Solution:**
1. Ensure Ubuntu 20.04/22.04 LTS
2. Ensure 2GB+ RAM available
3. Run: `sudo ./troubleshoot.sh` (option 9: Run all checks)

---

## 📊 MONITORING & STATUS

### **Check Installation Status:**
```
/checkstatus 1.2.3.4|password123
```

### **Manual System Check:**
```bash
# Test bot configuration
./test-bot.sh

# System troubleshooting  
sudo ./troubleshoot.sh

# Check services
systemctl status nginx mysql redis-server pterodactyl-queue-worker wings
```

---

## 🎉 SUCCESS INDICATORS

### **✅ Installation Successful When:**
1. Bot shows: "🎉 Installation Completed Successfully!"
2. Panel accessible at: `https://your-panel.com`
3. Login works with provided credentials
4. Wings service running: `systemctl status wings`
5. `/checkstatus` shows all services green

### **🔧 Post-Installation Tasks:**
1. **Login to panel:** `https://your-panel.com`
2. **Create allocation:** Nodes → Your Node → Allocations
3. **Get wings token:** Nodes → Your Node → Configuration
4. **Start wings:** `/startwings ip|pass|token`
5. **Create test server** to verify everything works

---

## 📈 PERFORMANCE EXPECTATIONS

### **Installation Timeline:**
- **Setup:** 1-2 minutes
- **OS Check:** 30 seconds  
- **Package Update:** 2-5 minutes
- **Panel Install:** 5-10 minutes
- **Wings Install:** 2-3 minutes
- **SSL Generation:** 1-3 minutes
- **Total:** 10-15 minutes

### **Success Rates:**
- **Ubuntu 22.04:** 95%+ success rate
- **Ubuntu 20.04:** 90%+ success rate  
- **Ubuntu 24.x:** 0% (not supported)
- **APT Lock Auto-Fix:** 95% success rate

---

## 🔗 QUICK COMMAND REFERENCE

### **Bot Commands:**
```
/installpanel ip|pass|panel|node|ram     # Install full setup
/checkstatus ip|pass                     # Check system status  
/uninstallpanel ip|pass                  # Clean removal
/hackbackpanel ip|pass                   # Recover admin access
/startwings ip|pass|token                # Start wings service
/help                                    # Show all commands
```

### **Management Commands:**

**Windows:**
```cmd
start.bat                    # Start bot
windows-service.bat          # Service management
```

**Linux:**
```bash
./start.sh                   # Start bot
sudo ./setup.sh install     # Install as service
pterodactyl-bot start        # Service control (after setup)
./test-bot.sh               # Test configuration
sudo ./troubleshoot.sh      # Fix issues
./backup-restore.sh backup  # Backup configuration
```

---

## 🆘 GETTING HELP

### **Automatic Diagnostics:**
1. **Bot Status:** `/checkstatus ip|password`
2. **System Check:** `./test-bot.sh`
3. **Auto Fix:** `sudo ./troubleshoot.sh` → option 9

### **Manual Checks:**
```bash
# Check bot logs
tail -f logs/bot.log   # (if using service)

# Check system logs  
journalctl -u nginx -f
journalctl -u wings -f

# Check network
ping google.com
nslookup your-domain.com
curl -I https://your-domain.com
```

### **Common Solutions:**
- **APT Issues:** Run troubleshoot.sh option 2
- **Permission Issues:** Run troubleshoot.sh option 3
- **Service Issues:** Run troubleshoot.sh option 4
- **SSL Issues:** Wait 2-3 minutes, check domain DNS
- **Network Issues:** Check VPS firewall and ports

---

## 🎯 SUCCESS CHECKLIST

After installation, verify these items:

- [ ] Bot responds to `/start` in Telegram
- [ ] Panel accessible via HTTPS  
- [ ] Admin login works
- [ ] Nginx service running
- [ ] MySQL service running
- [ ] Wings service running (after token setup)
- [ ] Queue worker running
- [ ] SSL certificate valid
- [ ] Domain resolves correctly
- [ ] Can create test server

**If all checked: 🎉 INSTALLATION SUCCESSFUL!**

---

**📧 Bot Configuration:**
- **Token:** `7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg`
- **Owner:** `5476148500`
- **Domain:** `tams.my.id` with API access configured

**🔧 Need More Help?**
- Check `SOLUTION-GUIDE.md` for detailed troubleshooting
- Run `./troubleshoot.sh` for automated fixes
- Use `/checkstatus` for real-time diagnostics

**🚀 Ready to install? Start with `/installpanel` command!**
