# VIO Super AI - Mac System Monitor Demo Output

This shows the exact visual output when running on macOS:

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

## Features Demonstrated

### Visual Design
- **Header**: Uses double-line box characters (╔═╗║╚╝) to display system model and RAM
- **Sections**: Clean minimalist sections using light box characters (┌─└│├)
- **Progress Bars**: Unicode block characters (█ for filled, ░ for empty)
- **Separator**: Horizontal line (━) at bottom

### Real-Time Data
- **CPU**: Shows percentage with visual bar and load averages (1/5/15 min)
- **RAM**: Shows percentage, used/cached/free in GB, and memory pressure level
- **Disk**: Shows usage percentage and space in GiB
- **Processes**: Top 3 memory consumers with percentage
- **System Info**: Uptime, process count, date/time, update interval

### Behind the Scenes
When thresholds are exceeded:
- Automatically identifies resource-heavy processes
- Uses ML model to predict problematic processes
- Terminates processes gracefully (or force-kills if needed)
- Sends macOS native notifications
- Logs critical events for PEC notification system
- Updates ML model based on process behavior

### Machine Learning
The monitor learns over time:
- Tracks CPU/RAM usage patterns per process
- Calculates risk scores based on historical behavior
- Predicts which processes will become problematic
- Adjusts termination decisions based on past kills

## Installation

Simply run:
```bash
./install.sh
```

Or manually:
```bash
pip3 install psutil
python3 mac_system_monitor.py
```

## Configuration

Edit `CONFIG` dictionary in the script:
- `RAM_THRESHOLD`: Default 85% - when to start killing processes
- `CPU_THRESHOLD`: Default 90% - CPU threshold for process termination
- `CHECK_INTERVAL`: Default 2 seconds - refresh rate
- `ML_ENABLED`: Default True - enable machine learning predictions
- `AUTO_KILL_ENABLED`: Default True - enable automatic process termination
- `NOTIFICATIONS_ENABLED`: Default True - enable macOS notifications
- `PEC_NOTIFICATIONS`: Default True - enable PEC logging

## Auto-Launch

Add to `~/.zshrc`:
```bash
# VIO Super AI - Mac System Monitor
python3 /path/to/mac_system_monitor.py
```

---

**VIO Super AI** - World Record Level Quality
