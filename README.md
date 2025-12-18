# ai-scripts-elite

## VIO Super AI - Mac System Monitor & Auto-Optimizer

Professional-grade system monitoring and auto-optimization tool for macOS with machine learning capabilities.

**© 2025 VIO Super AI - Proprietary Software - All Rights Reserved**

### 🎨 Two Versions Available

This repository includes **TWO complete versions** to choose from:

1. **MINIMALIST Edition** (`mac_system_monitor.py`) - Clean, simple design
2. **ELITE Edition** (`mac_system_monitor_elite.py`) - Enhanced graphics with emoji indicators

See [VERSION_COMPARISON.md](VERSION_COMPARISON.md) and [SIDE_BY_SIDE_COMPARISON.md](SIDE_BY_SIDE_COMPARISON.md) for detailed comparisons.

### 📱 NEW: iPhone Access & Email Notifications

**Access your Mac monitor from your iPhone 15!**

- 📧 **Email Notifications** - Receive status updates like GitHub notifications
- 🌐 **Web Dashboard** - Touch-friendly interface accessible from iPhone Safari
- 🔄 **Real-time Sync** - Monitor your Mac remotely, even when away from home
- 📱 **iOS Optimized** - Perfect for iPhone 15 with iOS Tahoe 2026/26.1

**See [IPHONE_GUIDE.md](IPHONE_GUIDE.md) for complete setup instructions!**

### 🌟 Features

- **Real-time System Monitoring**
  - CPU usage with load averages (1/5/15 min)
  - RAM usage with memory pressure indicators
  - Disk space monitoring
  - Process tracking with top memory consumers

- **Intelligent Auto-Optimization**
  - Automatically kills resource-heavy processes (configurable thresholds: RAM >85%, CPU >90%)
  - Machine learning prediction for problematic processes
  - Prevents system freezes before they occur

- **macOS Native Integration**
  - Native notification system via `osascript`
  - PEC (Posta Elettronica Certificata) notification logging
  - Clean, minimalist terminal UI matching macOS aesthetic

- **Auto-Launch Ready**
  - Can be configured to start automatically with Terminal
  - `.zshrc` and `.bashrc` integration support

### 📋 Requirements

- macOS (tested on Mac Air 2020 with 8GB RAM)
- Python 3.6+
- `psutil` library

### 🚀 Installation

#### Quick Install

```bash
# Clone the repository
git clone https://github.com/vio83/ai-scripts-elite.git
cd ai-scripts-elite

# Run the installation script
chmod +x install.sh
./install.sh
```

The installation script will:
1. Check Python and pip installation
2. Install required dependencies (`psutil`)
3. Make the monitor script executable
4. Optionally create a symlink for easy access
5. Optionally configure auto-launch on Terminal startup

#### Manual Install

```bash
# Install dependencies
pip3 install psutil

# Make the script executable
chmod +x mac_system_monitor.py

# Run the monitor
python3 mac_system_monitor.py
```

### 💻 Usage

#### MINIMALIST Edition (Clean Design)

```bash
python3 mac_system_monitor.py
```

#### ELITE Edition (Enhanced Graphics)

```bash
python3 mac_system_monitor_elite.py
```

#### 📱 Web Dashboard for iPhone

```bash
# Start the web dashboard
python3 web_dashboard.py

# Then on iPhone, open Safari and go to:
# http://YOUR_MAC_IP:5000
```

#### 📧 Email Notifications

```bash
# Configure email notifications
python3 email_notifier.py

# Edit the config file with your credentials
nano ~/.vio_super_ai/email_config.json
```

Or if you installed with symlink:

```bash
vio-monitor        # MINIMALIST version
vio-monitor-elite  # ELITE version
vio-dashboard      # Web dashboard
```

**For complete iPhone setup:** See [IPHONE_GUIDE.md](IPHONE_GUIDE.md)

#### Configuration

Edit the `CONFIG` dictionary in `mac_system_monitor.py` to customize behavior:

```python
CONFIG = {
    'RAM_THRESHOLD': 85,        # Kill processes when RAM exceeds this %
    'CPU_THRESHOLD': 90,        # Kill processes when CPU exceeds this %
    'CHECK_INTERVAL': 2,        # Update interval in seconds
    'HISTORY_SIZE': 100,        # Number of samples for ML model
    'ML_ENABLED': True,         # Enable machine learning predictions
    'NOTIFICATIONS_ENABLED': True,  # Enable macOS notifications
    'AUTO_KILL_ENABLED': True,  # Enable automatic process termination
    'PEC_NOTIFICATIONS': True,  # Enable PEC notification logging
}
```

#### Auto-Launch on Terminal Startup

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# VIO Super AI - Mac System Monitor Auto-Launch
python3 /path/to/mac_system_monitor.py
```

### 📊 Display Format

The monitor shows:

```
╔══════════════════════════════════════════════════════════════════════════╗
║           SYSTEM MONITOR - MAC AIR 2020 (8GB RAM)                        ║
╚══════════════════════════════════════════════════════════════════════════╝

┌─ CPU Usage
│ ██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13%
└─ Load (1/5/15 min): 7.43 4.37 3.179

┌─ RAM Usage (8GB Total)
│ ██████████████████████████████░░░░░░░░░░░░░░░░░░░░  61%
├─ Used: 0.9G | Cached: 0.3G | Free: 0.0G
└─ Memory Pressure: Moderate

┌─ Disk Usage
│ ███████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  31%
└─ Space: 11Gi / 228Gi

┌─ Top Memory Consumers
│ com.apple.WebKit.WebContent      2.3%
│ com.apple.dock.extra             1.8%
│ Safari                           1.4%
└─

┌─ System Info
│ Uptime: 1d 5h 55m  │  Processes: 464
│ Date: 2025-12-14 07:16:04
└─ Press Ctrl+C to exit  │  Update: every 2 seconds

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 🤖 Machine Learning

The monitor learns from process behavior over time:

- Tracks historical CPU and memory usage per process
- Records kill history to identify repeat offenders
- Calculates risk scores for proactive process management
- Model is saved to `~/.vio_super_ai/process_model.pkl`

Risk score calculation:
```python
risk_score = (
    kill_count * 10 +
    (max_cpu / 100) * 5 +
    (max_mem / 100) * 5 +
    (avg_cpu / 100) * 3 +
    (avg_mem / 100) * 3
)
```

### 🔔 Notifications

- **macOS Native**: Uses `osascript` for system notifications
- **PEC Logging**: Critical alerts logged to `~/.vio_super_ai/pec_notifications.log`
- **Session Reports**: Statistics saved to `~/.vio_super_ai/session_reports.json`

### 🛡️ Safety Features

- **Protected Processes**: System-critical processes are never terminated:
  - `kernel_task`, `launchd`, `WindowServer`, `loginwindow`
  - `systemstats`, `python3`, `Terminal`, `iTerm2`

- **Graceful Termination**: Processes are terminated gracefully first, force-killed only if necessary

- **One Process Per Cycle**: Only kills one process per monitoring cycle to maintain system stability

### 📝 Files & Data

- `~/.vio_super_ai/process_model.pkl` - Machine learning model data
- `~/.vio_super_ai/pec_notifications.log` - Critical alert log
- `~/.vio_super_ai/session_reports.json` - Session statistics (last 100 sessions)

### 🎨 Visual Design

**MINIMALIST Edition:**
- Clean, simple box-drawing characters (`┌─└│├`)
- Unicode progress bars (`█` filled, `░` empty)
- Subtle color coding for status indicators
- Professional minimalist layout

**ELITE Edition:**
- Enhanced box-drawing (`╔═╗║╚╝╟─╢`)
- Full VIO SUPER AI ASCII art header
- Emoji indicators (🟢🟡🔴🏆⚡🤖💾)
- Color-graded progress bars
- Multi-panel dashboard layout

See visual examples:
- [VISUAL_OUTPUT.txt](VISUAL_OUTPUT.txt) - Minimalist design
- [VISUAL_OUTPUT_ELITE.txt](VISUAL_OUTPUT_ELITE.txt) - ELITE design

### 🔧 Troubleshooting

**Issue**: "Permission denied" when killing processes
- **Solution**: Some processes require elevated privileges. The monitor will skip these.

**Issue**: `psutil` import error
- **Solution**: Install psutil: `pip3 install psutil`

**Issue**: Notifications not showing
- **Solution**: Check System Preferences > Notifications and ensure Terminal/iTerm2 has notification permissions

**Issue**: Monitor not auto-starting
- **Solution**: Verify the path in your `.zshrc`/`.bashrc` is correct and the file is sourced on shell startup

### 📄 License & Ownership

**PROPRIETARY SOFTWARE - ALL RIGHTS RESERVED**

This software is the exclusive property of **VIO Super AI**.

- ✅ **Private Use Only** - For owner's exclusive use
- ❌ **No Redistribution** - Cannot be shared, copied, or distributed
- ❌ **No Modification** - Cannot be modified by third parties
- 💰 **Commercial Licensing Available** - Contact VIO Super AI for licensing

**Copyright © 2025 VIO Super AI - All Rights Reserved**

See [LICENSE](LICENSE) for full legal terms.

### ⚖️ Important Notice

This code is **NOT open source**. If you wish to use this software, you must:
1. Contact VIO Super AI for permission
2. Negotiate and pay for a commercial license
3. Receive written authorization

Unauthorized use is prohibited and will result in legal action.

### 🤝 Contributing

This is proprietary software. Contributions are not accepted from external parties.

### 📞 Support

For issues or questions, please open an issue on GitHub.

---

**VIO Super AI** - World Record Level Quality - Professional Standards Edition