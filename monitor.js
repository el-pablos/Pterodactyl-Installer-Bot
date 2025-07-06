const { Client: ssh2 } = require('ssh2');
const cron = require('cron');
const config = require('./config');

// Monitor configuration
const MONITORING_INTERVAL = '*/5 * * * *'; // Every 5 minutes
const servers = [
  // Add your servers here
  // {
  //   name: "Production Panel",
  //   host: "1.2.3.4",
  //   password: "your_password",
  //   services: ["nginx", "mysql", "pterodactyl-queue-worker", "wings"]
  // }
];

class PterodactylMonitor {
  constructor() {
    this.alerts = [];
    this.lastCheck = null;
  }

  async checkServer(server) {
    return new Promise((resolve, reject) => {
      const ssh = new ssh2();
      const results = {
        server: server.name,
        timestamp: new Date().toISOString(),
        status: 'unknown',
        services: {},
        system: {},
        errors: []
      };

      ssh.on('ready', () => {
        this.checkServices(ssh, server.services)
          .then(serviceStatus => {
            results.services = serviceStatus;
            return this.checkSystem(ssh);
          })
          .then(systemInfo => {
            results.system = systemInfo;
            results.status = 'online';
            ssh.end();
            resolve(results);
          })
          .catch(error => {
            results.errors.push(error.message);
            results.status = 'error';
            ssh.end();
            resolve(results);
          });
      }).on('error', (err) => {
        results.status = 'offline';
        results.errors.push(`SSH Connection failed: ${err.message}`);
        reject(results);
      }).connect({
        host: server.host,
        port: 22,
        username: 'root',
        password: server.password
      });
    });
  }

  async checkServices(ssh, services) {
    const serviceStatus = {};
    
    for (const service of services) {
      try {
        const status = await this.executeCommand(ssh, `systemctl is-active ${service}`);
        serviceStatus[service] = status.trim() === 'active' ? 'running' : 'stopped';
      } catch (error) {
        serviceStatus[service] = 'error';
      }
    }
    
    return serviceStatus;
  }

  async checkSystem(ssh) {
    try {
      const [cpuInfo, memInfo, diskInfo, loadInfo] = await Promise.all([
        this.executeCommand(ssh, "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1"),
        this.executeCommand(ssh, "free -m | grep Mem | awk '{print $3/$2 * 100.0}'"),
        this.executeCommand(ssh, "df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1"),
        this.executeCommand(ssh, "uptime | awk -F'load average:' '{print $2}'")
      ]);

      return {
        cpu_usage: parseFloat(cpuInfo.trim()) || 0,
        memory_usage: parseFloat(memInfo.trim()) || 0,
        disk_usage: parseFloat(diskInfo.trim()) || 0,
        load_average: loadInfo.trim() || 'N/A'
      };
    } catch (error) {
      return {
        cpu_usage: 0,
        memory_usage: 0,
        disk_usage: 0,
        load_average: 'Error',
        error: error.message
      };
    }
  }

  executeCommand(ssh, command) {
    return new Promise((resolve, reject) => {
      ssh.exec(command, (err, stream) => {
        if (err) return reject(err);
        
        let output = '';
        stream.on('data', (data) => {
          output += data.toString();
        }).on('close', (code) => {
          if (code === 0) {
            resolve(output);
          } else {
            reject(new Error(`Command failed with exit code ${code}`));
          }
        });
      });
    });
  }

  generateReport(results) {
    const timestamp = new Date().toLocaleString();
    let report = `🔍 **Pterodactyl Monitor Report**\n`;
    report += `📅 **Time:** ${timestamp}\n\n`;

    results.forEach(result => {
      report += `🖥️ **Server:** ${result.server}\n`;
      report += `📊 **Status:** ${this.getStatusEmoji(result.status)} ${result.status.toUpperCase()}\n`;
      
      if (result.services) {
        report += `🔧 **Services:**\n`;
        Object.entries(result.services).forEach(([service, status]) => {
          const emoji = status === 'running' ? '✅' : '❌';
          report += `  ${emoji} ${service}: ${status}\n`;
        });
      }
      
      if (result.system && !result.system.error) {
        report += `💾 **System:**\n`;
        report += `  CPU: ${result.system.cpu_usage.toFixed(1)}%\n`;
        report += `  Memory: ${result.system.memory_usage.toFixed(1)}%\n`;
        report += `  Disk: ${result.system.disk_usage}%\n`;
        report += `  Load: ${result.system.load_average}\n`;
      }
      
      if (result.errors.length > 0) {
        report += `⚠️ **Errors:**\n`;
        result.errors.forEach(error => {
          report += `  • ${error}\n`;
        });
      }
      
      report += `\n`;
    });

    return report;
  }

  getStatusEmoji(status) {
    switch (status) {
      case 'online': return '🟢';
      case 'offline': return '🔴';
      case 'error': return '🟡';
      default: return '⚪';
    }
  }

  checkAlerts(results) {
    const alerts = [];
    
    results.forEach(result => {
      // Check if server is offline
      if (result.status === 'offline') {
        alerts.push(`🚨 **ALERT:** Server ${result.server} is OFFLINE!`);
      }
      
      // Check service status
      if (result.services) {
        Object.entries(result.services).forEach(([service, status]) => {
          if (status !== 'running') {
            alerts.push(`⚠️ **WARNING:** Service ${service} on ${result.server} is ${status}`);
          }
        });
      }
      
      // Check system resources
      if (result.system && !result.system.error) {
        if (result.system.cpu_usage > 90) {
          alerts.push(`🔥 **ALERT:** High CPU usage on ${result.server}: ${result.system.cpu_usage.toFixed(1)}%`);
        }
        if (result.system.memory_usage > 90) {
          alerts.push(`🔥 **ALERT:** High memory usage on ${result.server}: ${result.system.memory_usage.toFixed(1)}%`);
        }
        if (result.system.disk_usage > 90) {
          alerts.push(`🔥 **ALERT:** High disk usage on ${result.server}: ${result.system.disk_usage}%`);
        }
      }
    });
    
    return alerts;
  }

  async runMonitoring() {
    console.log('🔍 Starting monitoring check...');
    this.lastCheck = new Date();
    
    if (servers.length === 0) {
      console.log('⚠️ No servers configured for monitoring');
      return;
    }

    try {
      const results = await Promise.allSettled(
        servers.map(server => this.checkServer(server))
      );
      
      const processedResults = results.map(result => 
        result.status === 'fulfilled' ? result.value : result.reason
      );
      
      // Generate report
      const report = this.generateReport(processedResults);
      console.log(report);
      
      // Check for alerts
      const alerts = this.checkAlerts(processedResults);
      if (alerts.length > 0) {
        console.log('\n🚨 ALERTS:');
        alerts.forEach(alert => console.log(alert));
        this.alerts = alerts;
      } else {
        console.log('✅ All systems normal');
        this.alerts = [];
      }
      
    } catch (error) {
      console.error('❌ Monitoring error:', error);
    }
  }

  startScheduledMonitoring() {
    console.log(`🕐 Starting scheduled monitoring (${MONITORING_INTERVAL})`);
    
    const job = new cron.CronJob(MONITORING_INTERVAL, () => {
      this.runMonitoring();
    }, null, true, 'Asia/Jakarta');
    
    // Run initial check
    this.runMonitoring();
    
    return job;
  }

  getStatus() {
    return {
      lastCheck: this.lastCheck,
      alerts: this.alerts,
      servers: servers.length
    };
  }
}

// Create monitor instance
const monitor = new PterodactylMonitor();

// CLI interface
if (require.main === module) {
  console.log('🔍 Pterodactyl Panel Monitor');
  console.log('============================');
  
  const args = process.argv.slice(2);
  
  if (args.includes('--once')) {
    console.log('Running one-time check...');
    monitor.runMonitoring();
  } else if (args.includes('--scheduled')) {
    console.log('Starting scheduled monitoring...');
    monitor.startScheduledMonitoring();
  } else {
    console.log('Usage:');
    console.log('  node monitor.js --once      # Run one-time check');
    console.log('  node monitor.js --scheduled # Start scheduled monitoring');
    console.log('');
    console.log('⚠️ Configure servers in monitor.js file first!');
  }
}

module.exports = PterodactylMonitor;
