# VIO Super AI - Quick Start Guide

## 🚀 Installation (3 Steps)

### Step 1: Clone & Navigate
```bash
git clone https://github.com/vio83/ai-scripts-elite.git
cd ai-scripts-elite
```

### Step 2: Run Installer
```bash
chmod +x install.sh
./install.sh
```

The installer will:
- ✓ Check Python 3 and pip
- ✓ Install psutil dependency
- ✓ Create optional symlink (`vio-monitor`)
- ✓ Configure auto-launch (optional)

### Step 3: Start Monitoring
```bash
python3 mac_system_monitor.py
```

Or if you created the symlink:
```bash
vio-monitor
```

## ⚙️ Quick Configuration

Open `mac_system_monitor.py` and edit the `CONFIG` section (around line 36):

```python
CONFIG = {
    'RAM_THRESHOLD': 85,        # Kill processes when RAM > 85%
    'CPU_THRESHOLD': 90,        # Kill processes when CPU > 90%
    'CHECK_INTERVAL': 2,        # Update every 2 seconds
    'ML_ENABLED': True,         # Use machine learning predictions
    'AUTO_KILL_ENABLED': True,  # Automatically kill heavy processes
    'NOTIFICATIONS_ENABLED': True,  # Show macOS notifications
    'PEC_NOTIFICATIONS': True,  # Log critical alerts
}
```

## 🎯 Common Tasks

### Make it Start Automatically

Add to your `~/.zshrc` (or `~/.bashrc`):
```bash
# Auto-start VIO Super AI Monitor
python3 ~/path/to/mac_system_monitor.py
```

### Run in Background

```bash
# Start in background
nohup python3 mac_system_monitor.py > /dev/null 2>&1 &

# Check if running
ps aux | grep mac_system_monitor

# Stop
pkill -f mac_system_monitor
```

### View Logs

```bash
# View PEC notifications (critical alerts)
cat ~/.vio_super_ai/pec_notifications.log

# View session reports
cat ~/.vio_super_ai/session_reports.json | python3 -m json.tool
```

### Reset Machine Learning Model

```bash
rm ~/.vio_super_ai/process_model.pkl
```

## 🔧 Troubleshooting

### "ModuleNotFoundError: No module named 'psutil'"
```bash
pip3 install psutil
# or
sudo pip3 install psutil
```

### "Permission denied" when killing processes
Some system processes require elevated privileges and will be skipped automatically.

### Notifications not showing
Check: System Preferences > Notifications > Terminal (or iTerm2)
Ensure "Allow Notifications" is enabled.

### Monitor uses too much CPU
Increase `CHECK_INTERVAL` to 5 or 10 seconds:
```python
'CHECK_INTERVAL': 5,  # Update every 5 seconds
```

## 📊 Understanding the Display

```
┌─ CPU Usage
│ ██████░░░░  13%          ← Visual bar + percentage
└─ Load: 7.43 4.37 3.18   ← Load averages (1/5/15 min)
```

- **Load < # of CPU cores**: System is healthy
- **Load > # of CPU cores**: System is overloaded

```
┌─ RAM Usage (8GB Total)
│ ██████████████████░░  61%
└─ Memory Pressure: Moderate  ← Low / Moderate / High
```

- **Low**: < 60% RAM usage
- **Moderate**: 60-85% RAM usage  
- **High**: > 85% RAM usage (auto-kill may trigger)

## 🤖 Machine Learning Explained

The monitor learns from process behavior:

1. **Tracking**: Records CPU/RAM usage per process
2. **Scoring**: Calculates risk scores based on:
   - Past kill history
   - Maximum resource usage
   - Average resource usage
3. **Prediction**: Identifies processes likely to cause problems
4. **Action**: Prioritizes which processes to terminate first

Risk scores update in real-time and are saved between sessions.

## 🛡️ Safety

Protected processes (never killed):
- `kernel_task`, `launchd`, `WindowServer`
- `loginwindow`, `systemstats`
- `python3`, `Terminal`, `iTerm2`

Process termination:
1. First tries graceful `SIGTERM`
2. Waits 3 seconds
3. Force kills with `SIGKILL` if needed

Only kills **one process per cycle** to maintain stability.

## 📞 Need Help?

1. Check the full README.md for detailed documentation
2. View DEMO.md for visual examples
3. Open an issue on GitHub

## ⚡ Pro Tips

- **Lower thresholds** (70% RAM, 80% CPU) for aggressive optimization
- **Disable auto-kill** while doing intensive work (compiling, rendering)
- **Check session reports** to see patterns in killed processes
- **Run in tmux/screen** to keep monitoring when Terminal closes

---

**VIO Super AI** - World Record Level Quality
