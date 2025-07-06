# 🚀 DEPLOYMENT GUIDE - Pterodactyl Bot v2.1

**Production deployment guide for Pterodactyl Panel Installer Bot**

## 📋 DEPLOYMENT OVERVIEW

This guide covers deploying the bot in production environments with proper security, monitoring, and maintenance procedures.

## 🔧 PRODUCTION DEPLOYMENT OPTIONS

### **Option 1: Linux VPS/Server (Recommended)**
- **Best for:** Production environments, 24/7 availability
- **Requirements:** Ubuntu 20.04/22.04 LTS, 1GB RAM, 10GB storage
- **Features:** Systemd service, auto-restart, logging, monitoring

### **Option 2: Windows Server**
- **Best for:** Windows-based infrastructure
- **Requirements:** Windows Server 2019+, 2GB RAM, 20GB storage  
- **Features:** Windows Service, GUI management, event logs

### **Option 3: Docker Container**
- **Best for:** Containerized environments, scalability
- **Requirements:** Docker host, persistent volume
- **Features:** Easy deployment, resource isolation

### **Option 4: Cloud Platforms**
- **Best for:** Managed infrastructure, auto-scaling
- **Requirements:** Cloud account, API access
- **Features:** High availability, managed resources

---

## 🖥️ LINUX PRODUCTION DEPLOYMENT

### **Step 1: Server Preparation**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install requirements
sudo apt install -y curl wget git nginx software-properties-common

# Install Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### **Step 2: Create Deployment User**

```bash
# Create dedicated user
sudo useradd -r -d /opt/pterodactyl-bot -s /bin/bash pterodactyl-bot
sudo mkdir -p /opt/pterodactyl-bot
sudo mkdir -p /var/log/pterodactyl-bot

# Set permissions
sudo chown pterodactyl-bot:pterodactyl-bot /opt/pterodactyl-bot
sudo chown pterodactyl-bot:pterodactyl-bot /var/log/pterodactyl-bot
```

### **Step 3: Deploy Bot Files**

```bash
# Switch to bot directory
cd /opt/pterodactyl-bot

# Clone/copy bot files (choose one)
# Option A: Git clone
sudo git clone https://github.com/ndikafath/pterodactyl-installer-bot.git .

# Option B: Manual upload
# Upload your bot files to /opt/pterodactyl-bot/

# Set ownership
sudo chown -R pterodactyl-bot:pterodactyl-bot .

# Install dependencies
sudo -u pterodactyl-bot npm install --production
```

### **Step 4: Configure Environment**

```bash
# Copy environment template
sudo -u pterodactyl-bot cp .env.example .env

# Edit configuration
sudo nano .env

# Set secure permissions
sudo chmod 600 .env
```

**Required .env variables:**
```bash
BOT_TOKEN=7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg
OWNER_ID=5476148500
DEFAULT_EMAIL=ndikafath@ndikafath.store
LOGGING_ENABLED=true
SAVE_LOGS_TO_FILE=true
LOG_FILE_PATH=/var/log/pterodactyl-bot/bot.log
```

### **Step 5: Create Systemd Service**

```bash
# Create service file
sudo tee /etc/systemd/system/pterodactyl-bot.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Panel Installer Bot
After=network.target
Wants=network.target

[Service]
Type=simple
User=pterodactyl-bot
Group=pterodactyl-bot
WorkingDirectory=/opt/pterodactyl-bot
ExecStart=/usr/bin/node bot.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production
StandardOutput=append:/var/log/pterodactyl-bot/output.log
StandardError=append:/var/log/pterodactyl-bot/error.log

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/pterodactyl-bot /var/log/pterodactyl-bot
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
sudo systemctl enable pterodactyl-bot
sudo systemctl start pterodactyl-bot

# Check status
sudo systemctl status pterodactyl-bot
```

### **Step 6: Setup Log Rotation**

```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/pterodactyl-bot > /dev/null << 'EOF'
/var/log/pterodactyl-bot/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
    su pterodactyl-bot pterodactyl-bot
}
EOF
```

### **Step 7: Setup Monitoring**

```bash
# Create health check script
sudo tee /usr/local/bin/pterodactyl-bot-health > /dev/null << 'EOF'
#!/bin/bash
SERVICE="pterodactyl-bot"
LOGFILE="/var/log/pterodactyl-bot/health.log"

if ! systemctl is-active --quiet $SERVICE; then
    echo "$(date): Service down, restarting..." >> $LOGFILE
    systemctl restart $SERVICE
    sleep 5
    if systemctl is-active --quiet $SERVICE; then
        echo "$(date): Service restarted successfully" >> $LOGFILE
    else
        echo "$(date): Failed to restart service" >> $LOGFILE
    fi
else
    echo "$(date): Service running normally" >> $LOGFILE
fi
EOF

sudo chmod +x /usr/local/bin/pterodactyl-bot-health

# Add to crontab (check every 5 minutes)
(sudo crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/pterodactyl-bot-health") | sudo crontab -
```

---

## 🪟 WINDOWS PRODUCTION DEPLOYMENT

### **Step 1: Install Requirements**

1. **Install Node.js LTS:** https://nodejs.org/
2. **Install Git:** https://git-scm.com/download/win
3. **Install Visual Studio Build Tools** (for native dependencies)

### **Step 2: Create Service Directory**

```cmd
# Create directories
mkdir C:\Services\PterodactylBot
mkdir C:\Services\PterodactylBot\logs

# Copy bot files to C:\Services\PterodactylBot\
```

### **Step 3: Install as Windows Service**

```cmd
# Open Command Prompt as Administrator
cd C:\Services\PterodactylBot

# Install dependencies
npm install --production

# Run Windows service installer
windows-service.bat

# Select option 1: Install Service
```

### **Step 4: Configure Service**

```cmd
# Edit configuration
notepad .env

# Test service
net start PterodactylBot
net stop PterodactylBot
```

### **Step 5: Setup Monitoring**

1. **Windows Event Logs:** Check Application logs for bot events
2. **Performance Monitor:** Monitor CPU/RAM usage
3. **Task Scheduler:** Create health check tasks
4. **Service Manager:** Configure recovery options

---

## 🐳 DOCKER DEPLOYMENT

### **Step 1: Create Dockerfile**

```dockerfile
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy app source
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S botuser && \
    adduser -S botuser -u 1001

# Set permissions
RUN chown -R botuser:botuser /app
USER botuser

# Expose health check port (optional)
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "console.log('Health check passed')" || exit 1

# Start bot
CMD ["node", "bot.js"]
```

### **Step 2: Create docker-compose.yml**

```yaml
version: '3.8'

services:
  pterodactyl-bot:
    build: .
    container_name: pterodactyl-bot
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - BOT_TOKEN=7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg
      - OWNER_ID=5476148500
      - DEFAULT_EMAIL=ndikafath@ndikafath.store
    volumes:
      - ./logs:/app/logs
      - ./config:/app/config
    networks:
      - bot-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  bot-network:
    driver: bridge

volumes:
  bot-logs:
  bot-config:
```

### **Step 3: Deploy with Docker**

```bash
# Build and start
docker-compose up -d

# Check logs
docker-compose logs -f pterodactyl-bot

# Update deployment
docker-compose pull && docker-compose up -d
```

---

## ☁️ CLOUD PLATFORM DEPLOYMENT

### **AWS EC2 Deployment**

```bash
# Launch Ubuntu 22.04 LTS instance
# Security Group: Allow SSH (22), HTTP (80), HTTPS (443)

# Connect via SSH
ssh -i your-key.pem ubuntu@your-instance-ip

# Follow Linux deployment steps
curl -sSL https://raw.githubusercontent.com/ndikafath/pterodactyl-installer-bot/main/setup.sh | sudo bash
```

### **Google Cloud Platform**

```bash
# Create VM instance
gcloud compute instances create pterodactyl-bot \
  --image-family ubuntu-2204-lts \
  --image-project ubuntu-os-cloud \
  --machine-type e2-small \
  --zone us-central1-a

# Connect and deploy
gcloud compute ssh pterodactyl-bot --zone us-central1-a
```

### **DigitalOcean Droplet**

```bash
# Create droplet via web interface or API
# Choose Ubuntu 22.04 LTS, 1GB RAM

# Connect and deploy
ssh root@your-droplet-ip

# Run automated setup
wget -O - https://raw.githubusercontent.com/ndikafath/pterodactyl-installer-bot/main/setup.sh | bash
```

---

## 🔒 SECURITY CONSIDERATIONS

### **Bot Security**

1. **Token Protection:**
   ```bash
   # Secure .env file
   chmod 600 .env
   chown root:root .env
   ```

2. **User Isolation:**
   ```bash
   # Run as non-root user
   sudo -u pterodactyl-bot node bot.js
   ```

3. **Network Security:**
   ```bash
   # Firewall configuration
   sudo ufw enable
   sudo ufw allow ssh
   sudo ufw allow 80
   sudo ufw allow 443
   ```

### **SSH Security**

1. **Key-based Authentication:**
   ```bash
   # Disable password authentication
   echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
   systemctl restart ssh
   ```

2. **Fail2Ban Protection:**
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   ```

### **System Security**

1. **Automatic Updates:**
   ```bash
   # Enable unattended upgrades
   sudo apt install unattended-upgrades
   sudo dpkg-reconfigure unattended-upgrades
   ```

2. **Log Monitoring:**
   ```bash
   # Monitor auth logs
   tail -f /var/log/auth.log
   ```

---

## 📊 MONITORING & MAINTENANCE

### **System Monitoring**

```bash
# Service status
systemctl status pterodactyl-bot

# Resource usage
htop
df -h
free -h

# Network connections
ss -tuln | grep :22

# Log analysis
journalctl -u pterodactyl-bot -f
tail -f /var/log/pterodactyl-bot/*.log
```

### **Performance Metrics**

- **CPU Usage:** Should be < 10% normally
- **Memory Usage:** Should be < 100MB
- **Disk Usage:** Monitor log files growth
- **Network:** Monitor API call rates

### **Backup Strategy**

```bash
# Automated backup
./backup-restore.sh auto 7

# Manual backup
./backup-restore.sh backup

# Backup to remote storage
rsync -av /opt/pterodactyl-bot/ user@backup-server:/backups/pterodactyl-bot/
```

### **Update Procedures**

```bash
# Update bot code
cd /opt/pterodactyl-bot
sudo -u pterodactyl-bot git pull
sudo -u pterodactyl-bot npm update

# Restart service
sudo systemctl restart pterodactyl-bot

# Verify update
sudo systemctl status pterodactyl-bot
```

---

## 🔧 TROUBLESHOOTING PRODUCTION ISSUES

### **Service Won't Start**

```bash
# Check service status
systemctl status pterodactyl-bot

# Check logs
journalctl -u pterodactyl-bot --no-pager

# Check configuration
node -c /opt/pterodactyl-bot/bot.js

# Fix permissions
sudo chown -R pterodactyl-bot:pterodactyl-bot /opt/pterodactyl-bot
```

### **High Resource Usage**

```bash
# Monitor processes
top -p $(pgrep -f "node bot.js")

# Check memory leaks
ps aux | grep node

# Restart service
sudo systemctl restart pterodactyl-bot
```

### **Bot Not Responding**

```bash
# Test bot connectivity
curl -s "https://api.telegram.org/bot7884808609:AAGBltt756PA1ftjTc67q_rsTlAsnGP6GVg/getMe"

# Check network connectivity
ping api.telegram.org

# Verify configuration
cat /opt/pterodactyl-bot/.env | grep BOT_TOKEN
```

---

## 📈 SCALING CONSIDERATIONS

### **Horizontal Scaling**
- Deploy multiple bot instances for redundancy
- Use load balancer for webhook mode
- Implement shared state storage (Redis)

### **Vertical Scaling**
- Increase VPS resources as needed
- Monitor performance metrics
- Optimize Node.js memory settings

### **Geographic Distribution**
- Deploy in multiple regions
- Use CDN for static assets
- Implement region-specific routing

---

## 🎯 PRODUCTION CHECKLIST

**Pre-Deployment:**
- [ ] Bot token configured and tested
- [ ] Domain/DNS properly configured
- [ ] SSL certificates valid
- [ ] Firewall rules configured
- [ ] Backup strategy implemented

**Post-Deployment:**
- [ ] Service running and enabled
- [ ] Logs properly configured
- [ ] Monitoring setup complete
- [ ] Health checks passing
- [ ] Security hardening applied

**Ongoing Maintenance:**
- [ ] Regular updates applied
- [ ] Logs rotated and archived
- [ ] Performance monitored
- [ ] Backups verified
- [ ] Security patches applied

---

**🎉 DEPLOYMENT COMPLETE!**

Your Pterodactyl Panel Installer Bot is now running in production with proper monitoring, security, and maintenance procedures.

**📧 Production Configuration:**
- **Service:** `systemctl status pterodactyl-bot`
- **Logs:** `/var/log/pterodactyl-bot/`
- **Config:** `/opt/pterodactyl-bot/.env`
- **Health:** `/usr/local/bin/pterodactyl-bot-health`

**🔧 Management Commands:**
- **Status:** `systemctl status pterodactyl-bot`
- **Restart:** `systemctl restart pterodactyl-bot`
- **Logs:** `journalctl -u pterodactyl-bot -f`
- **Update:** `cd /opt/pterodactyl-bot && git pull && systemctl restart pterodactyl-bot`
