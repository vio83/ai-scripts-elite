#!/usr/bin/env python3
"""
VIO Super AI - Email Notification Module
Sends progress updates via email
© 2025 VIO Super AI - Proprietary Software
"""

import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import json
from pathlib import Path

class EmailNotifier:
    """Email notification system for VIO Super AI Monitor"""
    
    def __init__(self, config_file=None):
        """Initialize email notifier with configuration"""
        self.config_dir = Path.home() / '.vio_super_ai'
        self.config_dir.mkdir(exist_ok=True)
        
        if config_file:
            self.config_path = Path(config_file)
        else:
            self.config_path = self.config_dir / 'email_config.json'
        
        self.load_config()
    
    def load_config(self):
        """Load email configuration from file"""
        if self.config_path.exists():
            try:
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                    self.smtp_server = config.get('smtp_server', 'smtp.gmail.com')
                    self.smtp_port = config.get('smtp_port', 587)
                    self.sender_email = config.get('sender_email', '')
                    self.sender_password = config.get('sender_password', '')
                    self.recipient_email = config.get('recipient_email', '')
                    self.enabled = config.get('enabled', False)
            except Exception as e:
                print(f"Error loading email config: {e}")
                self.set_defaults()
        else:
            self.set_defaults()
            self.save_default_config()
    
    def set_defaults(self):
        """Set default configuration"""
        self.smtp_server = 'smtp.gmail.com'
        self.smtp_port = 587
        self.sender_email = ''
        self.sender_password = ''
        self.recipient_email = ''
        self.enabled = False
    
    def save_default_config(self):
        """Save default configuration template"""
        config = {
            'smtp_server': self.smtp_server,
            'smtp_port': self.smtp_port,
            'sender_email': 'your-email@gmail.com',
            'sender_password': 'your-app-password',
            'recipient_email': 'recipient@example.com',
            'enabled': False,
            'instructions': {
                'gmail': 'Use App Password from Google Account Security',
                'smtp_server': 'Gmail: smtp.gmail.com, Outlook: smtp-mail.outlook.com',
                'smtp_port': 'Usually 587 for TLS or 465 for SSL'
            }
        }
        
        try:
            with open(self.config_path, 'w') as f:
                json.dump(config, f, indent=2)
            print(f"Email config template created at: {self.config_path}")
            print("Please edit the file with your email credentials")
        except Exception as e:
            print(f"Error saving config: {e}")
    
    def send_email(self, subject, body_text, body_html=None):
        """Send email notification"""
        if not self.enabled:
            print("Email notifications disabled. Enable in config file.")
            return False
        
        if not all([self.sender_email, self.sender_password, self.recipient_email]):
            print("Email configuration incomplete. Check config file.")
            return False
        
        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = self.sender_email
            message["To"] = self.recipient_email
            
            # Add plain text version
            part1 = MIMEText(body_text, "plain")
            message.attach(part1)
            
            # Add HTML version if provided
            if body_html:
                part2 = MIMEText(body_html, "html")
                message.attach(part2)
            
            # Create secure connection and send
            context = ssl.create_default_context()
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls(context=context)
                server.login(self.sender_email, self.sender_password)
                server.sendmail(self.sender_email, self.recipient_email, message.as_string())
            
            print(f"Email sent successfully: {subject}")
            return True
            
        except Exception as e:
            print(f"Error sending email: {e}")
            return False
    
    def send_status_update(self, stats, killed_processes_count):
        """Send system monitor status update"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        subject = f"VIO Super AI Monitor - Status Update {timestamp}"
        
        body_text = f"""
VIO Super AI System Monitor - Status Update
{'=' * 60}

Timestamp: {timestamp}

SYSTEM STATUS:
--------------
CPU Usage: {stats.get('cpu_percent', 0):.1f}%
RAM Usage: {stats.get('ram_percent', 0):.1f}%
Memory Pressure: {stats.get('memory_pressure', 'Unknown')}
Disk Usage: {stats.get('disk_percent', 0):.1f}%

Load Averages: {stats.get('load_avg_1', 0):.2f} / {stats.get('load_avg_5', 0):.2f} / {stats.get('load_avg_15', 0):.2f}

OPTIMIZATION:
-------------
Processes Killed: {killed_processes_count}
Uptime: {stats.get('uptime_days', 0)}d {stats.get('uptime_hours', 0)}h {stats.get('uptime_minutes', 0)}m
Active Processes: {stats.get('process_count', 0)}

{'=' * 60}
VIO Super AI - Monitoring Your System
© 2025 VIO Super AI - Proprietary Software
"""
        
        body_html = f"""
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; }}
        .container {{ max-width: 600px; margin: 20px auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 24px; }}
        .stats {{ margin: 20px 0; }}
        .stat-item {{ display: flex; justify-content: space-between; padding: 10px; border-bottom: 1px solid #eee; }}
        .stat-label {{ font-weight: bold; color: #333; }}
        .stat-value {{ color: #667eea; }}
        .alert {{ background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0; }}
        .success {{ background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin: 10px 0; }}
        .footer {{ text-align: center; color: #666; font-size: 12px; margin-top: 20px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 VIO Super AI Monitor</h1>
            <p>System Status Update</p>
        </div>
        
        <div class="stats">
            <h2>📊 System Status</h2>
            <div class="stat-item">
                <span class="stat-label">⚡ CPU Usage:</span>
                <span class="stat-value">{stats.get('cpu_percent', 0):.1f}%</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">💾 RAM Usage:</span>
                <span class="stat-value">{stats.get('ram_percent', 0):.1f}%</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">📈 Memory Pressure:</span>
                <span class="stat-value">{stats.get('memory_pressure', 'Unknown')}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">💿 Disk Usage:</span>
                <span class="stat-value">{stats.get('disk_percent', 0):.1f}%</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">📊 Load Avg:</span>
                <span class="stat-value">{stats.get('load_avg_1', 0):.2f} / {stats.get('load_avg_5', 0):.2f} / {stats.get('load_avg_15', 0):.2f}</span>
            </div>
        </div>
        
        <div class="stats">
            <h2>🤖 Optimization Status</h2>
            <div class="stat-item">
                <span class="stat-label">⚔️ Processes Terminated:</span>
                <span class="stat-value">{killed_processes_count}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">🕐 System Uptime:</span>
                <span class="stat-value">{stats.get('uptime_days', 0)}d {stats.get('uptime_hours', 0)}h {stats.get('uptime_minutes', 0)}m</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">📊 Active Processes:</span>
                <span class="stat-value">{stats.get('process_count', 0)}</span>
            </div>
        </div>
        
        <div class="success">
            ✅ System is being actively monitored and optimized
        </div>
        
        <div class="footer">
            <p><strong>VIO Super AI</strong> - Intelligent System Monitoring</p>
            <p>© 2025 VIO Super AI - Proprietary Software</p>
            <p>{timestamp}</p>
        </div>
    </div>
</body>
</html>
"""
        
        return self.send_email(subject, body_text, body_html)
    
    def send_critical_alert(self, alert_type, message, stats):
        """Send critical system alert"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        subject = f"🚨 VIO Super AI - CRITICAL ALERT: {alert_type}"
        
        body_text = f"""
🚨 CRITICAL SYSTEM ALERT 🚨
{'=' * 60}

Alert Type: {alert_type}
Timestamp: {timestamp}

MESSAGE:
{message}

CURRENT SYSTEM STATUS:
CPU: {stats.get('cpu_percent', 0):.1f}%
RAM: {stats.get('ram_percent', 0):.1f}%
Memory Pressure: {stats.get('memory_pressure', 'Unknown')}

ACTION REQUIRED:
Please check your system immediately.

{'=' * 60}
VIO Super AI - System Alert
© 2025 VIO Super AI
"""
        
        body_html = f"""
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; }}
        .container {{ max-width: 600px; margin: 20px auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }}
        .header {{ background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; }}
        .alert-critical {{ background-color: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 20px 0; }}
        .alert-critical h2 {{ color: #721c24; margin-top: 0; }}
        .stats {{ margin: 20px 0; padding: 15px; background-color: #fff3cd; border-radius: 5px; }}
        .footer {{ text-align: center; color: #666; font-size: 12px; margin-top: 20px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚨 CRITICAL ALERT</h1>
            <p>VIO Super AI System Monitor</p>
        </div>
        
        <div class="alert-critical">
            <h2>⚠️ {alert_type}</h2>
            <p><strong>{message}</strong></p>
        </div>
        
        <div class="stats">
            <h3>Current System Status:</h3>
            <p><strong>CPU:</strong> {stats.get('cpu_percent', 0):.1f}%</p>
            <p><strong>RAM:</strong> {stats.get('ram_percent', 0):.1f}%</p>
            <p><strong>Memory Pressure:</strong> {stats.get('memory_pressure', 'Unknown')}</p>
        </div>
        
        <p style="text-align: center; font-weight: bold; color: #dc3545;">
            ⚠️ ACTION REQUIRED - Please check your system immediately
        </p>
        
        <div class="footer">
            <p><strong>VIO Super AI</strong> - System Alert</p>
            <p>© 2025 VIO Super AI - Proprietary Software</p>
            <p>{timestamp}</p>
        </div>
    </div>
</body>
</html>
"""
        
        return self.send_email(subject, body_text, body_html)
    
    def send_work_session_update(self, session_info):
        """Send work session progress update (like GitHub notifications)"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        subject = f"VIO Super AI - Work Session Update: {session_info.get('title', 'Progress')}"
        
        body_text = f"""
VIO Super AI - Work Session Update
{'=' * 60}

{session_info.get('title', 'Work Session Progress')}

Timestamp: {timestamp}

STATUS:
{session_info.get('status', 'In Progress')}

DETAILS:
{session_info.get('details', 'Working on system optimization...')}

STATISTICS:
- Duration: {session_info.get('duration', 'N/A')}
- Tasks Completed: {session_info.get('tasks_completed', 0)}
- Tasks Remaining: {session_info.get('tasks_remaining', 0)}

{'=' * 60}
VIO Super AI - Keeping You Updated
© 2025 VIO Super AI
"""
        
        body_html = f"""
<html>
<head>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background-color: #f6f8fa; }}
        .container {{ max-width: 600px; margin: 20px auto; background: white; border: 1px solid #d0d7de; border-radius: 6px; }}
        .header {{ background: #0969da; color: white; padding: 16px 20px; border-radius: 6px 6px 0 0; }}
        .header h1 {{ margin: 0; font-size: 20px; font-weight: 600; }}
        .content {{ padding: 20px; }}
        .status {{ background-color: #ddf4ff; border-left: 3px solid #0969da; padding: 12px; margin: 15px 0; border-radius: 3px; }}
        .details {{ background-color: #f6f8fa; padding: 15px; border-radius: 6px; margin: 15px 0; }}
        .stats {{ display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin: 15px 0; }}
        .stat-box {{ background: #f6f8fa; padding: 12px; border-radius: 6px; text-align: center; }}
        .stat-box .label {{ font-size: 12px; color: #57606a; }}
        .stat-box .value {{ font-size: 24px; font-weight: bold; color: #0969da; }}
        .footer {{ background: #f6f8fa; padding: 16px; border-top: 1px solid #d0d7de; text-align: center; font-size: 12px; color: #57606a; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 {session_info.get('title', 'Work Session Progress')}</h1>
        </div>
        
        <div class="content">
            <div class="status">
                <strong>📊 Status:</strong> {session_info.get('status', 'In Progress')}
            </div>
            
            <div class="details">
                <h3 style="margin-top: 0;">Details:</h3>
                <p>{session_info.get('details', 'Working on system optimization...')}</p>
            </div>
            
            <div class="stats">
                <div class="stat-box">
                    <div class="label">⏱️ Duration</div>
                    <div class="value">{session_info.get('duration', 'N/A')}</div>
                </div>
                <div class="stat-box">
                    <div class="label">✅ Completed</div>
                    <div class="value">{session_info.get('tasks_completed', 0)}</div>
                </div>
            </div>
            
            <p style="color: #57606a; font-size: 14px;">
                <strong>Tasks Remaining:</strong> {session_info.get('tasks_remaining', 0)}
            </p>
        </div>
        
        <div class="footer">
            <p><strong>VIO Super AI</strong> - Intelligent Work Session Monitoring</p>
            <p>© 2025 VIO Super AI - Proprietary Software</p>
            <p>{timestamp}</p>
        </div>
    </div>
</body>
</html>
"""
        
        return self.send_email(subject, body_text, body_html)


# Example usage
if __name__ == '__main__':
    print("VIO Super AI - Email Notifier Setup")
    print("=" * 60)
    
    notifier = EmailNotifier()
    
    print("\nEmail notifier initialized.")
    print(f"Configuration file: {notifier.config_path}")
    print("\nTo enable email notifications:")
    print("1. Edit the configuration file with your email settings")
    print("2. Set 'enabled': true in the config")
    print("3. Use Gmail App Password (not regular password)")
    print("\nFor Gmail App Password:")
    print("- Go to Google Account Security")
    print("- Enable 2-Factor Authentication")
    print("- Generate App Password for 'Mail'")
